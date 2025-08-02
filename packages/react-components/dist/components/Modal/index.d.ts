import React from 'react';
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
export declare function BaseModal({ isOpen, onClose, title, size, closeOnOverlayClick, closeOnEscape, children, className, headerClassName, contentClassName, showCloseButton, customCloseButton, zIndex }: BaseModalProps): import("react/jsx-runtime").JSX.Element | null;
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
export declare function ConfirmModal({ isOpen, onClose, onConfirm, title, message, confirmText, cancelText, confirmButtonStyle, loading }: ConfirmModalProps): import("react/jsx-runtime").JSX.Element;
export default BaseModal;
//# sourceMappingURL=index.d.ts.map