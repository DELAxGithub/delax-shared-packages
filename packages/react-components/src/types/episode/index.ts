/**
 * エピソードステータス型定義
 * 10段階の制作進行ステータスを定義
 */
export type EpisodeStatus = 
  | '台本作成中'
  | '素材準備'
  | '素材確定'
  | '編集中'
  | '試写1'
  | '修正1'
  | 'MA中'
  | '初稿完成'
  | '修正中'
  | '完パケ納品';

/**
 * エピソードタイプ
 */
export type EpisodeType = 'interview' | 'vtr';

/**
 * 素材ステータス
 */
export type MaterialStatus = '○' | '△' | '×';

/**
 * エピソードステータス情報
 */
export interface EpisodeStatusInfo {
  id: number;
  status_name: EpisodeStatus;
  status_order: number;
  color_code: string;
  created_at: string;
}

/**
 * エピソード基本情報
 */
export interface Episode {
  id: string; // LA-INT001, ORN-EP01 など (primary key)
  title: string;
  episode_type: EpisodeType;
  season: number;
  episode_number: number;
  
  // 共通項目
  script_url: string | null;
  current_status: EpisodeStatus;
  assignee: string | null;
  due_date: string | null;
  
  // インタビュー番組用
  guest_name: string | null;
  recording_date: string | null;
  recording_location: string | null;
  
  // VTR番組用  
  material_status: MaterialStatus | null;
  
  // タイムスタンプ
  created_at: string;
  updated_at: string;
}

/**
 * エピソード詳細情報（ステータス情報を含む）
 */
export interface EpisodeDetail extends Episode {
  status_order: number;
  color_code: string;
  series_name: string | null;
  is_overdue: boolean;
  days_overdue: number | null;
}

/**
 * ステータス変更履歴
 */
export interface StatusHistory {
  id: number;
  episode_id: string;
  old_status: EpisodeStatus | null;
  new_status: EpisodeStatus;
  changed_by: string;
  change_reason: string | null;
  changed_at: string;
}

/**
 * 新規エピソード作成用型
 */
export type NewEpisode = Omit<Episode, 'created_at' | 'updated_at'>;

/**
 * エピソード更新用型
 */
export type UpdateEpisode = Partial<Omit<Episode, 'id' | 'created_at' | 'updated_at'>>;

/**
 * ステータスの順序定義
 * 制作進行の論理的な順序を表現
 */
export const STATUS_ORDER: EpisodeStatus[] = [
  '台本作成中',
  '素材準備',
  '素材確定',
  '編集中',
  '試写1',
  '修正1',
  'MA中',
  '初稿完成',
  '修正中',
  '完パケ納品'
] as const;

/**
 * ステータスの色定義
 * 各ステータスに対応するHEX色コード
 */
export const STATUS_COLORS: Record<EpisodeStatus, string> = {
  '台本作成中': '#6B7280', // Gray-500
  '素材準備': '#8B5CF6',   // Violet-500
  '素材確定': '#6366F1',   // Indigo-500
  '編集中': '#3B82F6',     // Blue-500
  '試写1': '#06B6D4',      // Cyan-500
  '修正1': '#10B981',      // Emerald-500
  'MA中': '#84CC16',       // Lime-500
  '初稿完成': '#EAB308',   // Yellow-500
  '修正中': '#F59E0B',     // Amber-500
  '完パケ納品': '#22C55E'  // Green-500
} as const;

/**
 * 手戻り可能なステータスの定義
 * 各ステータスから戻ることができるステータスを定義
 */
export const REVERTIBLE_STATUS: Record<EpisodeStatus, EpisodeStatus[]> = {
  '台本作成中': [],
  '素材準備': ['台本作成中'],
  '素材確定': ['素材準備'],
  '編集中': ['素材確定'],
  '試写1': ['編集中'],
  '修正1': ['編集中'],
  'MA中': ['修正1'],
  '初稿完成': ['修正1', 'MA中'],
  '修正中': ['編集中'],
  '完パケ納品': []
} as const;

/**
 * ステータス管理ユーティリティ
 */
export class StatusManager {
  /**
   * ステータスの進捗率を計算
   */
  static getProgressPercentage(status: EpisodeStatus): number {
    const statusIndex = STATUS_ORDER.indexOf(status);
    return ((statusIndex + 1) / STATUS_ORDER.length) * 100;
  }

  /**
   * ステータスの順序インデックスを取得
   */
  static getStatusOrder(status: EpisodeStatus): number {
    return STATUS_ORDER.indexOf(status);
  }

  /**
   * 次のステータスを取得
   */
  static getNextStatus(currentStatus: EpisodeStatus): EpisodeStatus | null {
    const currentIndex = STATUS_ORDER.indexOf(currentStatus);
    return currentIndex < STATUS_ORDER.length - 1 ? STATUS_ORDER[currentIndex + 1] : null;
  }

  /**
   * 前のステータスを取得
   */
  static getPreviousStatus(currentStatus: EpisodeStatus): EpisodeStatus | null {
    const currentIndex = STATUS_ORDER.indexOf(currentStatus);
    return currentIndex > 0 ? STATUS_ORDER[currentIndex - 1] : null;
  }

  /**
   * ステータス変更が可能かチェック
   */
  static canChangeStatus(from: EpisodeStatus, to: EpisodeStatus): boolean {
    const fromIndex = STATUS_ORDER.indexOf(from);
    const toIndex = STATUS_ORDER.indexOf(to);
    
    // 前進は常に可能
    if (toIndex > fromIndex) return true;
    
    // 手戻りは定義されたもののみ可能
    return REVERTIBLE_STATUS[from].includes(to);
  }
}