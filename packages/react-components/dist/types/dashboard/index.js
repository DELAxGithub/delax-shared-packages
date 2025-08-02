/**
 * ダッシュボードユーティリティクラス
 */
export class DashboardUtils {
    /**
     * ウィジェットをソート順で並び替え
     */
    static sortWidgets(widgets) {
        return [...widgets].sort((a, b) => a.sort_order - b.sort_order);
    }
    /**
     * アクティブなウィジェットのみをフィルター
     */
    static filterActiveWidgets(widgets) {
        return widgets.filter(widget => widget.is_active);
    }
    /**
     * ウィジェットタイプでフィルター
     */
    static filterByType(widgets, type) {
        return widgets.filter(widget => widget.widget_type === type);
    }
    /**
     * ウィジェットのコンテンツが有効かチェック
     */
    static isValidContent(widget) {
        switch (widget.widget_type) {
            case 'quicklinks':
                return !!widget.content.links?.length;
            case 'memo':
                return !!widget.content.text?.trim();
            case 'tasks':
                return !!widget.content.tasks?.length;
            case 'schedule':
                return true; // スケジュールは常に有効
            case 'custom':
                return !!widget.content.data;
            default:
                return false;
        }
    }
    /**
     * 新しいソート順を生成
     */
    static generateSortOrder(widgets) {
        return widgets.length > 0 ? Math.max(...widgets.map(w => w.sort_order)) + 1 : 1;
    }
}
//# sourceMappingURL=index.js.map