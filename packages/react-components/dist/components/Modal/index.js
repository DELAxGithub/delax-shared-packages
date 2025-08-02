import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useEffect, useRef } from 'react';
import { X } from 'lucide-react';
/**
 * ベースModalコンポーネント
 *
 * 再利用可能なモーダルダイアログのベースコンポーネントです。
 * 各種サイズ、キーボード操作、オーバーレイクリック対応などの基本機能を提供します。
 *
 * @param props BaseModalProps
 * @returns JSX要素
 *
 * @example
 * ```tsx
 * // 基本的な使用
 * <BaseModal
 *   isOpen={isModalOpen}
 *   onClose={() => setIsModalOpen(false)}
 *   title="設定"
 * >
 *   <div>モーダルの内容</div>
 * </BaseModal>
 *
 * // 大きいサイズでオーバーレイクリック無効
 * <BaseModal
 *   isOpen={isModalOpen}
 *   onClose={() => setIsModalOpen(false)}
 *   title="詳細設定"
 *   size="lg"
 *   closeOnOverlayClick={false}
 * >
 *   <FormContent />
 * </BaseModal>
 *
 * // カスタムスタイリング
 * <BaseModal
 *   isOpen={isModalOpen}
 *   onClose={() => setIsModalOpen(false)}
 *   title="カスタムモーダル"
 *   className="custom-modal"
 *   headerClassName="bg-blue-100"
 *   contentClassName="p-6"
 * >
 *   <CustomContent />
 * </BaseModal>
 * ```
 */
export function BaseModal({ isOpen, onClose, title, size = 'md', closeOnOverlayClick = true, closeOnEscape = true, children, className = '', headerClassName = '', contentClassName = '', showCloseButton = true, customCloseButton, zIndex = 50 }) {
    const modalRef = useRef(null);
    // サイズクラスの定義
    const sizeClasses = {
        sm: 'max-w-md',
        md: 'max-w-lg',
        lg: 'max-w-2xl',
        xl: 'max-w-4xl',
        full: 'max-w-full mx-4'
    };
    // ESCキーでモーダルを閉じる
    useEffect(() => {
        if (!isOpen || !closeOnEscape)
            return;
        const handleEscape = (event) => {
            if (event.key === 'Escape') {
                onClose();
            }
        };
        document.addEventListener('keydown', handleEscape);
        return () => document.removeEventListener('keydown', handleEscape);
    }, [isOpen, closeOnEscape, onClose]);
    // モーダルが開いている間はボディのスクロールを無効にする
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = 'hidden';
        }
        else {
            document.body.style.overflow = 'unset';
        }
        return () => {
            document.body.style.overflow = 'unset';
        };
    }, [isOpen]);
    // フォーカストラップ（基本実装）
    useEffect(() => {
        if (!isOpen)
            return;
        const modalElement = modalRef.current;
        if (!modalElement)
            return;
        // モーダルが開いた時に最初のフォーカス可能な要素にフォーカス
        const focusableElements = modalElement.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
        if (focusableElements.length > 0) {
            focusableElements[0].focus();
        }
    }, [isOpen]);
    // オーバーレイクリック処理
    const handleOverlayClick = (event) => {
        if (closeOnOverlayClick && event.target === event.currentTarget) {
            onClose();
        }
    };
    if (!isOpen)
        return null;
    return (_jsx("div", { className: `fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4`, style: { zIndex: zIndex }, onClick: handleOverlayClick, role: "dialog", "aria-modal": "true", "aria-labelledby": title ? 'modal-title' : undefined, children: _jsxs("div", { ref: modalRef, className: `
          bg-white rounded-lg shadow-xl w-full ${sizeClasses[size]} 
          max-h-[90vh] overflow-hidden flex flex-col
          transform transition-all duration-200 ease-out
          ${className}
        `, onClick: (e) => e.stopPropagation(), children: [(title || showCloseButton) && (_jsxs("div", { className: `flex items-center justify-between p-4 border-b border-gray-200 ${headerClassName}`, children: [title && (_jsx("h2", { id: "modal-title", className: "text-lg font-semibold text-gray-900", children: title })), showCloseButton && (_jsx("div", { className: "flex items-center", children: customCloseButton || (_jsx("button", { onClick: onClose, className: "text-gray-400 hover:text-gray-600 transition-colors p-1", "aria-label": "\u30E2\u30FC\u30C0\u30EB\u3092\u9589\u3058\u308B", children: _jsx(X, { size: 20 }) })) }))] })), _jsx("div", { className: `flex-1 overflow-y-auto ${contentClassName}`, children: children })] }) }));
}
/**
 * 確認ダイアログコンポーネント
 *
 * はい/いいえの確認を求める専用のモーダルダイアログです。
 *
 * @param props ConfirmModalProps
 * @returns JSX要素
 */
export function ConfirmModal({ isOpen, onClose, onConfirm, title, message, confirmText = '確認', cancelText = 'キャンセル', confirmButtonStyle = 'primary', loading = false }) {
    const buttonStyles = {
        primary: 'bg-blue-600 hover:bg-blue-700 text-white',
        danger: 'bg-red-600 hover:bg-red-700 text-white',
        warning: 'bg-yellow-600 hover:bg-yellow-700 text-white'
    };
    const handleConfirm = () => {
        onConfirm();
        if (!loading) {
            onClose();
        }
    };
    return (_jsx(BaseModal, { isOpen: isOpen, onClose: onClose, title: title, size: "sm", closeOnOverlayClick: !loading, closeOnEscape: !loading, children: _jsxs("div", { className: "p-6", children: [_jsx("p", { className: "text-gray-700 mb-6", children: message }), _jsxs("div", { className: "flex justify-end space-x-3", children: [_jsx("button", { onClick: onClose, disabled: loading, className: "px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors", children: cancelText }), _jsx("button", { onClick: handleConfirm, disabled: loading, className: `px-4 py-2 rounded-md font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors ${buttonStyles[confirmButtonStyle]}`, children: loading ? '処理中...' : confirmText })] })] }) }));
}
export default BaseModal;
//# sourceMappingURL=index.js.map