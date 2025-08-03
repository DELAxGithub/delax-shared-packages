import React, { useEffect, useRef } from 'react';
import { X } from 'lucide-react';

/**
 * ベースモーダルコンポーネントのプロパティ
 */
export interface BaseModalProps {
  /** モーダルが開いているかどうか */
  isOpen: boolean;
  /** モーダルを閉じる時のハンドラー */
  onClose: () => void;
  /** モーダルのタイトル */
  title?: string;
  /** 子要素 */
  children: React.ReactNode;
  /** サイズ */
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  /** 背景クリックで閉じるか */
  closeOnBackdropClick?: boolean;
  /** ESCキーで閉じるか */
  closeOnEscape?: boolean;
  /** 閉じるボタンを表示するか */
  showCloseButton?: boolean;
  /** カスタムクラス名 */
  className?: string;
  /** ヘッダーのカスタム要素 */
  headerContent?: React.ReactNode;
  /** フッターのカスタム要素 */
  footerContent?: React.ReactNode;
  /** Z-indexの値 */
  zIndex?: number;
}

/**
 * 汎用ベースモーダルコンポーネント
 * 
 * あらゆる用途に使用できる基本的なモーダルコンポーネント。
 * アクセシビリティ、キーボード操作、フォーカス管理に対応。
 * 
 * @example
 * ```tsx
 * <BaseModal
 *   isOpen={isModalOpen}
 *   onClose={() => setIsModalOpen(false)}
 *   title=\"設定\"
 *   size=\"md\"
 *   footerContent={
 *     <div className=\"flex gap-2\">
 *       <button onClick={onSave}>保存</button>
 *       <button onClick={onClose}>キャンセル</button>
 *     </div>
 *   }
 * >
 *   <SettingsForm />
 * </BaseModal>
 * ```
 */
export function BaseModal({
  isOpen,
  onClose,
  title,
  children,
  size = 'md',
  closeOnBackdropClick = true,
  closeOnEscape = true,
  showCloseButton = true,
  className = '',
  headerContent,
  footerContent,
  zIndex = 50
}: BaseModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  // モーダルサイズのクラス定義
  const sizeClasses = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
    full: 'max-w-full mx-4'
  };

  // ESCキーでの閉じる処理
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

  // フォーカス管理
  useEffect(() => {
    if (isOpen) {
      // モーダルが開く前のフォーカス要素を記録
      previousFocusRef.current = document.activeElement as HTMLElement;
      
      // モーダル内の最初のフォーカス可能要素にフォーカス
      setTimeout(() => {
        const focusableElements = modalRef.current?.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex=\"-1\"])'
        );
        if (focusableElements && focusableElements.length > 0) {
          (focusableElements[0] as HTMLElement).focus();
        }
      }, 100);
    } else {
      // モーダルが閉じた時に元の要素にフォーカスを戻す
      if (previousFocusRef.current) {
        previousFocusRef.current.focus();
      }
    }
  }, [isOpen]);

  // ボディのスクロールを制御
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }

    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  // Tab移動の制御
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Tab') {
      const focusableElements = modalRef.current?.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex=\"-1\"])'
      );
      
      if (focusableElements && focusableElements.length > 0) {
        const firstElement = focusableElements[0] as HTMLElement;
        const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;

        if (event.shiftKey) {
          // Shift + Tab
          if (document.activeElement === firstElement) {
            event.preventDefault();
            lastElement.focus();
          }
        } else {
          // Tab
          if (document.activeElement === lastElement) {
            event.preventDefault();
            firstElement.focus();
          }
        }
      }
    }
  };

  if (!isOpen) return null;

  const modalClasses = [
    'fixed inset-0 flex items-center justify-center p-4',
    `z-${zIndex}`
  ].join(' ');

  const overlayClasses = [
    'fixed inset-0 bg-black bg-opacity-50 transition-opacity',
    `z-${zIndex - 1}`
  ].join(' ');

  const contentClasses = [
    'bg-white rounded-lg shadow-xl transform transition-all w-full',
    sizeClasses[size],
    `z-${zIndex + 1}`,
    'max-h-[90vh] overflow-hidden flex flex-col',
    className
  ].filter(Boolean).join(' ');

  return (
    <>
      {/* オーバーレイ */}
      <div
        className={overlayClasses}
        onClick={closeOnBackdropClick ? onClose : undefined}
        aria-hidden=\"true\"
      />
      
      {/* モーダル */}
      <div className={modalClasses}>
        <div
          ref={modalRef}
          className={contentClasses}
          role=\"dialog\"
          aria-modal=\"true\"
          aria-labelledby={title ? 'modal-title' : undefined}
          onKeyDown={handleKeyDown}
        >
          {/* ヘッダー */}
          {(title || headerContent || showCloseButton) && (
            <div className=\"flex items-center justify-between p-4 border-b border-gray-200\">
              <div className=\"flex items-center gap-3\">
                {title && (
                  <h2 id=\"modal-title\" className=\"text-lg font-semibold text-gray-900\">
                    {title}
                  </h2>
                )}
                {headerContent}
              </div>
              
              {showCloseButton && (
                <button
                  onClick={onClose}
                  className=\"text-gray-400 hover:text-gray-600 transition-colors p-1\"
                  aria-label=\"モーダルを閉じる\"
                >
                  <X size={20} />
                </button>
              )}
            </div>
          )}
          
          {/* コンテンツ */}
          <div className=\"flex-1 overflow-y-auto p-4\">
            {children}
          </div>
          
          {/* フッター */}
          {footerContent && (
            <div className=\"border-t border-gray-200 p-4\">
              {footerContent}
            </div>
          )}
        </div>
      </div>
    </>
  );
}

/**
 * 確認モーダルのプロパティ
 */
export interface ConfirmModalProps {
  /** モーダルが開いているかどうか */
  isOpen: boolean;
  /** キャンセル時のハンドラー */
  onCancel: () => void;
  /** 確認時のハンドラー */
  onConfirm: () => void;
  /** タイトル */
  title: string;
  /** メッセージ */
  message: string;
  /** 確認ボタンのテキスト */
  confirmText?: string;
  /** キャンセルボタンのテキスト */
  cancelText?: string;
  /** 確認ボタンの色（危険な操作の場合はred） */
  confirmVariant?: 'primary' | 'danger';
  /** ローディング状態 */
  loading?: boolean;
}

/**
 * 確認用モーダルコンポーネント
 */
export function ConfirmModal({
  isOpen,
  onCancel,
  onConfirm,
  title,
  message,
  confirmText = '確認',
  cancelText = 'キャンセル',
  confirmVariant = 'primary',
  loading = false
}: ConfirmModalProps) {
  const confirmButtonClasses = confirmVariant === 'danger'
    ? 'bg-red-600 hover:bg-red-700 text-white'
    : 'bg-blue-600 hover:bg-blue-700 text-white';

  return (
    <BaseModal
      isOpen={isOpen}
      onClose={onCancel}
      title={title}
      size=\"sm\"
      footerContent={
        <div className=\"flex gap-2 justify-end\">
          <button
            onClick={onCancel}
            disabled={loading}
            className=\"px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50\"
          >
            {cancelText}
          </button>
          <button
            onClick={onConfirm}
            disabled={loading}
            className={`px-4 py-2 text-sm font-medium rounded-md transition-colors disabled:opacity-50 ${confirmButtonClasses}`}
          >
            {loading ? '処理中...' : confirmText}
          </button>
        </div>
      }
    >
      <p className=\"text-gray-600\">{message}</p>
    </BaseModal>
  );
}

export default BaseModal;