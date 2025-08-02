/**
 * ステータスの順序定義
 * 制作進行の論理的な順序を表現
 */
export const STATUS_ORDER = [
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
];
/**
 * ステータスの色定義
 * 各ステータスに対応するHEX色コード
 */
export const STATUS_COLORS = {
    '台本作成中': '#6B7280', // Gray-500
    '素材準備': '#8B5CF6', // Violet-500
    '素材確定': '#6366F1', // Indigo-500
    '編集中': '#3B82F6', // Blue-500
    '試写1': '#06B6D4', // Cyan-500
    '修正1': '#10B981', // Emerald-500
    'MA中': '#84CC16', // Lime-500
    '初稿完成': '#EAB308', // Yellow-500
    '修正中': '#F59E0B', // Amber-500
    '完パケ納品': '#22C55E' // Green-500
};
/**
 * 手戻り可能なステータスの定義
 * 各ステータスから戻ることができるステータスを定義
 */
export const REVERTIBLE_STATUS = {
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
};
/**
 * ステータス管理ユーティリティ
 */
export class StatusManager {
    /**
     * ステータスの進捗率を計算
     */
    static getProgressPercentage(status) {
        const statusIndex = STATUS_ORDER.indexOf(status);
        return ((statusIndex + 1) / STATUS_ORDER.length) * 100;
    }
    /**
     * ステータスの順序インデックスを取得
     */
    static getStatusOrder(status) {
        return STATUS_ORDER.indexOf(status);
    }
    /**
     * 次のステータスを取得
     */
    static getNextStatus(currentStatus) {
        const currentIndex = STATUS_ORDER.indexOf(currentStatus);
        return currentIndex < STATUS_ORDER.length - 1 ? STATUS_ORDER[currentIndex + 1] : null;
    }
    /**
     * 前のステータスを取得
     */
    static getPreviousStatus(currentStatus) {
        const currentIndex = STATUS_ORDER.indexOf(currentStatus);
        return currentIndex > 0 ? STATUS_ORDER[currentIndex - 1] : null;
    }
    /**
     * ステータス変更が可能かチェック
     */
    static canChangeStatus(from, to) {
        const fromIndex = STATUS_ORDER.indexOf(from);
        const toIndex = STATUS_ORDER.indexOf(to);
        // 前進は常に可能
        if (toIndex > fromIndex)
            return true;
        // 手戻りは定義されたもののみ可能
        return REVERTIBLE_STATUS[from].includes(to);
    }
}
//# sourceMappingURL=index.js.map