/**
 * エピソードステータス型定義
 * 10段階の制作進行ステータスを定義
 */
export type EpisodeStatus = '台本作成中' | '素材準備' | '素材確定' | '編集中' | '試写1' | '修正1' | 'MA中' | '初稿完成' | '修正中' | '完パケ納品';
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
    id: string;
    title: string;
    episode_type: EpisodeType;
    season: number;
    episode_number: number;
    script_url: string | null;
    current_status: EpisodeStatus;
    assignee: string | null;
    due_date: string | null;
    guest_name: string | null;
    recording_date: string | null;
    recording_location: string | null;
    material_status: MaterialStatus | null;
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
export declare const STATUS_ORDER: EpisodeStatus[];
/**
 * ステータスの色定義
 * 各ステータスに対応するHEX色コード
 */
export declare const STATUS_COLORS: Record<EpisodeStatus, string>;
/**
 * 手戻り可能なステータスの定義
 * 各ステータスから戻ることができるステータスを定義
 */
export declare const REVERTIBLE_STATUS: Record<EpisodeStatus, EpisodeStatus[]>;
/**
 * ステータス管理ユーティリティ
 */
export declare class StatusManager {
    /**
     * ステータスの進捗率を計算
     */
    static getProgressPercentage(status: EpisodeStatus): number;
    /**
     * ステータスの順序インデックスを取得
     */
    static getStatusOrder(status: EpisodeStatus): number;
    /**
     * 次のステータスを取得
     */
    static getNextStatus(currentStatus: EpisodeStatus): EpisodeStatus | null;
    /**
     * 前のステータスを取得
     */
    static getPreviousStatus(currentStatus: EpisodeStatus): EpisodeStatus | null;
    /**
     * ステータス変更が可能かチェック
     */
    static canChangeStatus(from: EpisodeStatus, to: EpisodeStatus): boolean;
}
//# sourceMappingURL=index.d.ts.map