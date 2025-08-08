/**
 * GitHub Projects v2 API client
 */

import { graphql } from '@octokit/graphql';
import type {
  ClassificationResult,
  GitHubOperationResult,
  ProjectField,
  ProjectInfo,
} from './types';

export class ProjectsApiClient {
  private graphqlWithAuth: typeof graphql;

  constructor(token: string) {
    this.graphqlWithAuth = graphql.defaults({
      headers: {
        authorization: `token ${token}`,
      },
    });
  }

  /**
   * Get project information by organization and project number
   */
  async getProject(org: string, projectNumber: number): Promise<ProjectInfo | null> {
    try {
      const query = `
        query($org: String!, $number: Int!) {
          organization(login: $org) {
            projectV2(number: $number) {
              id
              title
              url
              number
              fields(first: 20) {
                nodes {
                  ... on ProjectV2Field {
                    id
                    name
                    dataType
                  }
                  ... on ProjectV2SingleSelectField {
                    id
                    name
                    dataType
                    options {
                      id
                      name
                    }
                  }
                  ... on ProjectV2IterationField {
                    id
                    name
                    dataType
                    configuration {
                      iterations {
                        startDate
                        id
                        title
                      }
                    }
                  }
                }
              }
            }
          }
        }
      `;

      const response: any = await this.graphqlWithAuth(query, {
        org,
        number: projectNumber,
      });

      const project = response.organization?.projectV2;
      if (!project) {
        return null;
      }

      return {
        id: project.id,
        number: project.number,
        title: project.title,
        url: project.url,
        fields: project.fields.nodes.map((field: any) => ({
          id: field.id,
          name: field.name,
          dataType: field.dataType,
          options: field.options?.map((option: any) => ({
            id: option.id,
            name: option.name,
          })) || [],
        })),
      };
    } catch (error) {
      console.error('Failed to get project info:', error);
      return null;
    }
  }

  /**
   * Add issue to project and set field values
   */
  async addIssueToProject(
    projectId: string,
    issueId: string,
    classification: ClassificationResult
  ): Promise<GitHubOperationResult> {
    try {
      // First, add the item to the project
      const addItemMutation = `
        mutation($projectId: ID!, $contentId: ID!) {
          addProjectV2ItemByContentId(input: {
            projectId: $projectId
            contentId: $contentId
          }) {
            item {
              id
            }
          }
        }
      `;

      const addResponse: any = await this.graphqlWithAuth(addItemMutation, {
        projectId,
        contentId: issueId,
      });

      const itemId = addResponse.addProjectV2ItemByContentId.item.id;

      // Set field values if provided
      if (classification.projectFields && Object.keys(classification.projectFields).length > 0) {
        await this.setProjectFields(projectId, itemId, classification.projectFields);
      }

      return {
        success: true,
        projectItemId: itemId,
        details: { projectId, issueId, itemId },
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error adding to project',
        details: { projectId, issueId, classification },
      };
    }
  }

  /**
   * Set project field values for an item
   */
  async setProjectFields(
    projectId: string,
    itemId: string,
    fields: Record<string, string | number>
  ): Promise<void> {
    try {
      // Get project info to resolve field IDs and option IDs
      const project = await this.getProjectById(projectId);
      if (!project) {
        throw new Error('Project not found');
      }

      for (const [fieldName, value] of Object.entries(fields)) {
        const field = project.fields.find(f => f.name === fieldName);
        if (!field) {
          console.warn(`Field '${fieldName}' not found in project`);
          continue;
        }

        await this.updateProjectField(projectId, itemId, field, value);
      }
    } catch (error) {
      console.error('Failed to set project fields:', error);
      throw error;
    }
  }

  /**
   * Update a specific project field
   */
  private async updateProjectField(
    projectId: string,
    itemId: string,
    field: ProjectField,
    value: string | number
  ): Promise<void> {
    try {
      let mutation: string;
      let variables: Record<string, any>;

      switch (field.dataType) {
        case 'TEXT':
          mutation = `
            mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) {
              updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: {
                  text: $value
                }
              }) {
                projectV2Item {
                  id
                }
              }
            }
          `;
          variables = {
            projectId,
            itemId,
            fieldId: field.id,
            value: String(value),
          };
          break;

        case 'NUMBER':
          mutation = `
            mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Float!) {
              updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: {
                  number: $value
                }
              }) {
                projectV2Item {
                  id
                }
              }
            }
          `;
          variables = {
            projectId,
            itemId,
            fieldId: field.id,
            value: Number(value),
          };
          break;

        case 'SINGLE_SELECT':
          // Find option ID by name
          const option = field.options?.find(opt => opt.name === String(value));
          if (!option) {
            console.warn(`Option '${value}' not found for field '${field.name}'`);
            return;
          }

          mutation = `
            mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
              updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: {
                  singleSelectOptionId: $optionId
                }
              }) {
                projectV2Item {
                  id
                }
              }
            }
          `;
          variables = {
            projectId,
            itemId,
            fieldId: field.id,
            optionId: option.id,
          };
          break;

        case 'DATE':
          mutation = `
            mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Date!) {
              updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: {
                  date: $value
                }
              }) {
                projectV2Item {
                  id
                }
              }
            }
          `;
          variables = {
            projectId,
            itemId,
            fieldId: field.id,
            value: String(value),
          };
          break;

        default:
          console.warn(`Unsupported field type: ${field.dataType}`);
          return;
      }

      await this.graphqlWithAuth(mutation, variables);
    } catch (error) {
      console.error(`Failed to update field '${field.name}':`, error);
      throw error;
    }
  }

  /**
   * Get project by ID (used internally)
   */
  private async getProjectById(projectId: string): Promise<ProjectInfo | null> {
    try {
      const query = `
        query($projectId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              id
              title
              url
              number
              fields(first: 20) {
                nodes {
                  ... on ProjectV2Field {
                    id
                    name
                    dataType
                  }
                  ... on ProjectV2SingleSelectField {
                    id
                    name
                    dataType
                    options {
                      id
                      name
                    }
                  }
                  ... on ProjectV2IterationField {
                    id
                    name
                    dataType
                  }
                }
              }
            }
          }
        }
      `;

      const response: any = await this.graphqlWithAuth(query, { projectId });
      const project = response.node;

      if (!project) {
        return null;
      }

      return {
        id: project.id,
        number: project.number,
        title: project.title,
        url: project.url,
        fields: project.fields.nodes.map((field: any) => ({
          id: field.id,
          name: field.name,
          dataType: field.dataType,
          options: field.options?.map((option: any) => ({
            id: option.id,
            name: option.name,
          })) || [],
        })),
      };
    } catch (error) {
      console.error('Failed to get project by ID:', error);
      return null;
    }
  }

  /**
   * Get issue node ID from issue URL or number
   */
  async getIssueNodeId(owner: string, repo: string, issueNumber: number): Promise<string | null> {
    try {
      const query = `
        query($owner: String!, $repo: String!, $number: Int!) {
          repository(owner: $owner, name: $repo) {
            issue(number: $number) {
              id
            }
          }
        }
      `;

      const response: any = await this.graphqlWithAuth(query, {
        owner,
        repo,
        number: issueNumber,
      });

      return response.repository?.issue?.id || null;
    } catch (error) {
      console.error('Failed to get issue node ID:', error);
      return null;
    }
  }

  /**
   * Check if issue is already in project
   */
  async isIssueInProject(projectId: string, issueId: string): Promise<boolean> {
    try {
      const query = `
        query($projectId: ID!, $issueId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              items(first: 100) {
                nodes {
                  content {
                    ... on Issue {
                      id
                    }
                  }
                }
              }
            }
          }
        }
      `;

      const response: any = await this.graphqlWithAuth(query, {
        projectId,
        issueId,
      });

      const items = response.node?.items?.nodes || [];
      return items.some((item: any) => item.content?.id === issueId);
    } catch (error) {
      console.error('Failed to check if issue is in project:', error);
      return false;
    }
  }

  /**
   * Create default project field mappings based on classification
   */
  static createDefaultProjectFields(
    classification: ClassificationResult
  ): Record<string, string | number> {
    const fields: Record<string, string | number> = {};

    // Map priority to common field names
    switch (classification.priority) {
      case 'critical':
        fields.Priority = 'Critical';
        fields.Status = 'Todo';
        break;
      case 'high':
        fields.Priority = 'High';
        fields.Status = 'Todo';
        break;
      case 'medium':
        fields.Priority = 'Medium';
        fields.Status = 'Backlog';
        break;
      case 'low':
        fields.Priority = 'Low';
        fields.Status = 'Backlog';
        break;
    }

    // Estimate size based on labels
    if (classification.labels.includes('bug')) {
      fields.Type = 'Bug';
      fields.Size = 'Medium';
    } else if (classification.labels.includes('feature')) {
      fields.Type = 'Feature';
      fields.Size = 'Large';
    } else if (classification.labels.includes('documentation')) {
      fields.Type = 'Documentation';
      fields.Size = 'Small';
    }

    // Merge with explicit project fields from classification
    return { ...fields, ...classification.projectFields };
  }
}