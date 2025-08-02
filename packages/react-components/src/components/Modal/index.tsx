import React, { useEffect, useRef } from 'react';
import { X } from 'lucide-react';

/**
 * ベースModalコンポーネントのプロパティ
 */
export interface BaseModalProps {
  /** モーダルの表示状態 */
  isOpen: boolean;
  /** モーダルを閉じる関数 */
  onClose: () => void;
  /** モーダルのタイトル */
  title?: string;
  /** モーダルのサイズ */
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  /** 外部クリックで閉じるかどうか */
  closeOnOverlayClick?: boolean;
  /** ESCキーで閉じるかどうか */
  closeOnEscape?: boolean;
  /** モーダルの内容 */
  children: React.ReactNode;
  /** カスタムクラス名 */
  className?: string;
  /** ヘッダーのカスタムクラス名 */
  headerClassName?: string;
  /** コンテンツのカスタムクラス名 */
  contentClassName?: string;
  /** 閉じるボタンを表示するかどうか */
  showCloseButton?: boolean;
  /** カスタム閉じるボタン */
  customCloseButton?: React.ReactNode;
  /** Z-index */
  zIndex?: number;
}

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
export function BaseModal({
  isOpen,
  onClose,
  title,
  size = 'md',
  closeOnOverlayClick = true,
  closeOnEscape = true,
  children,
  className = '',
  headerClassName = '',
  contentClassName = '',
  showCloseButton = true,
  customCloseButton,
  zIndex = 50
}: BaseModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);

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
    if (!isOpen || !closeOnEscape) return;

    const handleEscape = (event: KeyboardEvent) => {
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
    } else {
      document.body.style.overflow = 'unset';
    }

    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  // フォーカストラップ（基本実装）
  useEffect(() => {
    if (!isOpen) return;

    const modalElement = modalRef.current;
    if (!modalElement) return;

    // モーダルが開いた時に最初のフォーカス可能な要素にフォーカス
    const focusableElements = modalElement.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    
    if (focusableElements.length > 0) {
      (focusableElements[0] as HTMLElement).focus();
    }
  }, [isOpen]);

  // オーバーレイクリック処理
  const handleOverlayClick = (event: React.MouseEvent<HTMLDivElement>) => {
    if (closeOnOverlayClick && event.target === event.currentTarget) {
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div
      className={`fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4`}
      style={{ zIndex: zIndex }}
      onClick={handleOverlayClick}
      role="dialog"
      aria-modal="true"
      aria-labelledby={title ? 'modal-title' : undefined}
    >
      <div
        ref={modalRef}
        className={`
          bg-white rounded-lg shadow-xl w-full ${sizeClasses[size]} 
          max-h-[90vh] overflow-hidden flex flex-col
          transform transition-all duration-200 ease-out
          ${className}
        `}
        onClick={(e) => e.stopPropagation()}
      >
        {/* ヘッダー */}
        {(title || showCloseButton) && (
          <div className={`flex items-center justify-between p-4 border-b border-gray-200 ${headerClassName}`}>
            {title && (
              <h2 id="modal-title" className="text-lg font-semibold text-gray-900">
                {title}
              </h2>
            )}
            {showCloseButton && (
              <div className="flex items-center">
                {customCloseButton || (
                  <button
                    onClick={onClose}
                    className="text-gray-400 hover:text-gray-600 transition-colors p-1"
                    aria-label="モーダルを閉じる"
                  >
                    <X size={20} />
                  </button>
                )}
              </div>
            )}
          </div>
        )}

        {/* コンテンツ */}
        <div className={`flex-1 overflow-y-auto ${contentClassName}`}>
          {children}
        </div>
      </div>
    </div>
  );
}

/**
 * 確認ダイアログの専用プロパティ
 */
export interface ConfirmModalProps {
  /** ダイアログの表示状態 */
  isOpen: boolean;
  /** ダイアログを閉じる関数 */
  onClose: () => void;
  /** 確認時のコールバック */
  onConfirm: () => void;
  /** タイトル */
  title: string;
  /** メッセージ */
  message: string;
  /** 確認ボタンのテキスト */
  confirmText?: string;
  /** キャンセルボタンのテキスト */
  cancelText?: string;
  /** 確認ボタンのスタイル */
  confirmButtonStyle?: 'primary' | 'danger' | 'warning';
  /** ローディング状態 */
  loading?: boolean;
}

/**
 * 確認ダイアログコンポーネント
 * 
 * はい/いいえの確認を求める専用のモーダルダイアログです。
 * 
 * @param props ConfirmModalProps
 * @returns JSX要素
 */
export function ConfirmModal({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = '確認',
  cancelText = 'キャンセル',
  confirmButtonStyle = 'primary',
  loading = false
}: ConfirmModalProps) {
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

  return (
    <BaseModal
      isOpen={isOpen}
      onClose={onClose}
      title={title}
      size="sm"
      closeOnOverlayClick={!loading}
      closeOnEscape={!loading}
    >
      <div className="p-6">
        <p className="text-gray-700 mb-6">{message}</p>
        <div className="flex justify-end space-x-3">
          <button
            onClick={onClose}
            disabled={loading}
            className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {cancelText}
          </button>
          <button
            onClick={handleConfirm}
            disabled={loading}
            className={`px-4 py-2 rounded-md font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors ${buttonStyles[confirmButtonStyle]}`}
          >
            {loading ? '処理中...' : confirmText}
          </button>
        </div>
      </div>
    </BaseModal>
  );
}

export default BaseModal;