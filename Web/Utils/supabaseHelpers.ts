import { SupabaseClient } from '@supabase/supabase-js';

/**
 * Supabase統合ヘルパー関数
 * 
 * 一般的なSupabase操作を簡単にするためのユーティリティ関数群
 * 型安全性とエラーハンドリングを強化
 */

export interface SupabaseQueryOptions {
  /** ソート設定 */
  orderBy?: {
    column: string;
    ascending?: boolean;
  };
  /** ページネーション */
  pagination?: {
    from: number;
    to: number;
  };
  /** 検索フィルター */
  filters?: Record<string, any>;
  /** 取得するカラム */
  select?: string;
}

export interface SupabaseResponse<T> {
  data: T[] | null;
  error: Error | null;
  count?: number;
}

/**
 * 汎用的なテーブル取得関数
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param options クエリオプション
 * @returns 取得結果
 * 
 * @example
 * ```typescript
 * const episodes = await fetchTable(supabase, 'episodes', {
 *   orderBy: { column: 'created_at', ascending: false },
 *   filters: { status: '編集中' },
 *   pagination: { from: 0, to: 9 }
 * });
 * ```
 */
export async function fetchTable<T = any>(
  supabase: SupabaseClient,
  tableName: string,
  options: SupabaseQueryOptions = {}
): Promise<SupabaseResponse<T>> {
  try {
    let query = supabase
      .from(tableName)
      .select(options.select || '*', { count: 'exact' });

    // フィルター適用
    if (options.filters) {
      Object.entries(options.filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          query = query.eq(key, value);
        }
      });
    }

    // ソート適用
    if (options.orderBy) {
      query = query.order(options.orderBy.column, { 
        ascending: options.orderBy.ascending ?? true 
      });
    }

    // ページネーション適用
    if (options.pagination) {
      query = query.range(options.pagination.from, options.pagination.to);
    }

    const { data, error, count } = await query;
    
    return {
      data: data as T[] | null,
      error: error ? new Error(error.message) : null,
      count: count || undefined
    };
  } catch (err) {
    return {
      data: null,
      error: err instanceof Error ? err : new Error('Unknown error occurred'),
      count: undefined
    };
  }
}

/**
 * 単一レコード取得
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param id レコードID
 * @param idColumn ID列名（デフォルト: 'id'）
 * @returns 取得結果
 */
export async function fetchById<T = any>(
  supabase: SupabaseClient,
  tableName: string,
  id: string | number,
  idColumn: string = 'id'
): Promise<{ data: T | null; error: Error | null }> {
  try {
    const { data, error } = await supabase
      .from(tableName)
      .select('*')
      .eq(idColumn, id)
      .single();

    return {
      data: data as T | null,
      error: error ? new Error(error.message) : null
    };
  } catch (err) {
    return {
      data: null,
      error: err instanceof Error ? err : new Error('Unknown error occurred')
    };
  }
}

/**
 * レコード挿入
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param data 挿入データ
 * @returns 挿入結果
 */
export async function insertRecord<T = any>(
  supabase: SupabaseClient,
  tableName: string,
  data: Omit<T, 'id' | 'created_at' | 'updated_at'>
): Promise<{ data: T | null; error: Error | null }> {
  try {
    const { data: insertedData, error } = await supabase
      .from(tableName)
      .insert([data])
      .select()
      .single();

    return {
      data: insertedData as T | null,
      error: error ? new Error(error.message) : null
    };
  } catch (err) {
    return {
      data: null,
      error: err instanceof Error ? err : new Error('Unknown error occurred')
    };
  }
}

/**
 * レコード更新
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param id レコードID
 * @param updates 更新データ
 * @param idColumn ID列名（デフォルト: 'id'）
 * @returns 更新結果
 */
export async function updateRecord<T = any>(
  supabase: SupabaseClient,
  tableName: string,
  id: string | number,
  updates: Partial<T>,
  idColumn: string = 'id'
): Promise<{ data: T | null; error: Error | null }> {
  try {
    const { data, error } = await supabase
      .from(tableName)
      .update(updates)
      .eq(idColumn, id)
      .select()
      .single();

    return {
      data: data as T | null,
      error: error ? new Error(error.message) : null
    };
  } catch (err) {
    return {
      data: null,
      error: err instanceof Error ? err : new Error('Unknown error occurred')
    };
  }
}

/**
 * レコード削除
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param id レコードID
 * @param idColumn ID列名（デフォルト: 'id'）
 * @returns 削除結果
 */
export async function deleteRecord(
  supabase: SupabaseClient,
  tableName: string,
  id: string | number,
  idColumn: string = 'id'
): Promise<{ success: boolean; error: Error | null }> {
  try {
    const { error } = await supabase
      .from(tableName)
      .delete()
      .eq(idColumn, id);

    return {
      success: !error,
      error: error ? new Error(error.message) : null
    };
  } catch (err) {
    return {
      success: false,
      error: err instanceof Error ? err : new Error('Unknown error occurred')
    };
  }
}

/**
 * バッチ操作（一括挿入）
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param dataArray 挿入データ配列
 * @param batchSize バッチサイズ（デフォルト: 1000）
 * @returns 操作結果
 */
export async function batchInsert<T = any>(
  supabase: SupabaseClient,
  tableName: string,
  dataArray: Omit<T, 'id' | 'created_at' | 'updated_at'>[],
  batchSize: number = 1000
): Promise<{ 
  successCount: number; 
  errorCount: number; 
  errors: Error[] 
}> {
  let successCount = 0;
  let errorCount = 0;
  const errors: Error[] = [];

  for (let i = 0; i < dataArray.length; i += batchSize) {
    const batch = dataArray.slice(i, i + batchSize);
    
    try {
      const { data, error } = await supabase
        .from(tableName)
        .insert(batch)
        .select();

      if (error) {
        errorCount += batch.length;
        errors.push(new Error(`Batch ${Math.floor(i / batchSize) + 1}: ${error.message}`));
      } else {
        successCount += batch.length;
      }
    } catch (err) {
      errorCount += batch.length;
      errors.push(err instanceof Error ? err : new Error(`Batch ${Math.floor(i / batchSize) + 1}: Unknown error`));
    }
  }

  return { successCount, errorCount, errors };
}

/**
 * リアルタイム購読ヘルパー
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param callback 変更時コールバック
 * @param filters フィルター条件
 * @returns 購読解除関数
 */
export function subscribeToTable<T = any>(
  supabase: SupabaseClient,
  tableName: string,
  callback: (payload: {
    eventType: 'INSERT' | 'UPDATE' | 'DELETE';
    new: T | null;
    old: T | null;
  }) => void,
  filters?: Record<string, any>
) {
  let subscription = supabase
    .channel(`${tableName}_changes`)
    .on('postgres_changes', 
      { 
        event: '*', 
        schema: 'public', 
        table: tableName,
        ...(filters && { filter: Object.entries(filters).map(([key, value]) => `${key}=eq.${value}`).join(',') })
      },
      (payload: any) => {
        callback({
          eventType: payload.eventType,
          new: payload.new,
          old: payload.old
        });
      }
    );

  subscription.subscribe();

  return () => {
    subscription.unsubscribe();
  };
}

/**
 * フルテキスト検索（PostgreSQL専用）
 * 
 * @param supabase Supabaseクライアント
 * @param tableName テーブル名
 * @param searchTerm 検索語
 * @param searchColumns 検索対象列
 * @param options その他オプション
 * @returns 検索結果
 */
export async function fullTextSearch<T = any>(
  supabase: SupabaseClient,
  tableName: string,
  searchTerm: string,
  searchColumns: string[],
  options: SupabaseQueryOptions = {}
): Promise<SupabaseResponse<T>> {
  try {
    let query = supabase
      .from(tableName)
      .select(options.select || '*', { count: 'exact' });

    // OR条件でマルチカラム検索
    const searchConditions = searchColumns
      .map(column => `${column}.ilike.%${searchTerm}%`)
      .join(',');
    
    query = query.or(searchConditions);

    // その他のオプション適用
    if (options.filters) {
      Object.entries(options.filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          query = query.eq(key, value);
        }
      });
    }

    if (options.orderBy) {
      query = query.order(options.orderBy.column, { 
        ascending: options.orderBy.ascending ?? true 
      });
    }

    if (options.pagination) {
      query = query.range(options.pagination.from, options.pagination.to);
    }

    const { data, error, count } = await query;
    
    return {
      data: data as T[] | null,
      error: error ? new Error(error.message) : null,
      count: count || undefined
    };
  } catch (err) {
    return {
      data: null,
      error: err instanceof Error ? err : new Error('Unknown error occurred'),
      count: undefined
    };
  }
}