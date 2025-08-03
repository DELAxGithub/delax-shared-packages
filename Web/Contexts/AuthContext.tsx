import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { SupabaseClient, User, Session } from '@supabase/supabase-js';

/**
 * 認証設定
 */
export interface AuthConfig {
  /** 認証後のリダイレクトURL */
  redirectUrl?: string;
  /** ログイン後のデフォルトルート */
  defaultRoute?: string;
  /** ログインページのルート */
  loginRoute?: string;
  /** 自動サインイン機能を有効にするか */
  autoSignIn?: boolean;
  /** セッション永続化の設定 */
  persistence?: 'local' | 'session' | 'none';
}

/**
 * 認証コンテキストの型
 */
export interface AuthContextType {
  /** 現在のユーザー */
  user: User | null;
  /** セッション情報 */
  session: Session | null;
  /** ローディング状態 */
  loading: boolean;
  /** エラー情報 */
  error: string | null;
  /** サインイン（メール/パスワード） */
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  /** サインアップ */
  signUp: (email: string, password: string, metadata?: Record<string, any>) => Promise<{ error: Error | null }>;
  /** マジックリンクサインイン */
  signInWithMagicLink: (email: string) => Promise<{ error: Error | null }>;
  /** OAuth認証 */
  signInWithOAuth: (provider: 'google' | 'github' | 'facebook' | 'twitter') => Promise<{ error: Error | null }>;
  /** サインアウト */
  signOut: () => Promise<{ error: Error | null }>;
  /** パスワードリセット */
  resetPassword: (email: string) => Promise<{ error: Error | null }>;
  /** プロフィール更新 */
  updateProfile: (updates: { email?: string; password?: string; data?: Record<string, any> }) => Promise<{ error: Error | null }>;
  /** エラーをクリア */
  clearError: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

/**
 * 認証プロバイダーのプロパティ
 */
export interface AuthProviderProps {
  /** Supabaseクライアント */
  supabase: SupabaseClient;
  /** 認証設定 */
  config?: AuthConfig;
  /** 子要素 */
  children: ReactNode;
}

/**
 * Supabase認証プロバイダー
 * 
 * Supabaseを使用した認証機能を提供するコンテキストプロバイダー。
 * 各種認証方法、セッション管理、エラーハンドリングを包括的にサポート。
 * 
 * @example
 * ```tsx
 * import { createClient } from '@supabase/supabase-js';
 * import { AuthProvider, useAuth } from '@delax/shared-components';
 * 
 * const supabase = createClient(url, key);
 * 
 * function App() {
 *   return (
 *     <AuthProvider 
 *       supabase={supabase}
 *       config={{
 *         defaultRoute: '/dashboard',
 *         loginRoute: '/login'
 *       }}
 *     >
 *       <AppContent />
 *     </AuthProvider>
 *   );
 * }
 * 
 * function LoginForm() {
 *   const { signIn, loading, error } = useAuth();
 *   // ... ログインフォームの実装
 * }
 * ```
 */
export function AuthProvider({ 
  supabase, 
  config = {},
  children 
}: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // 初期化とセッション監視
  useEffect(() => {
    // 現在のセッションを取得
    supabase.auth.getSession().then(({ data: { session }, error }) => {
      if (error) {
        setError(error.message);
      } else {
        setSession(session);
        setUser(session?.user ?? null);
      }
      setLoading(false);
    });

    // 認証状態の変更を監視
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        setLoading(false);

        // リダイレクト処理
        if (event === 'SIGNED_IN' && config.defaultRoute) {
          // ここではリダイレクトロジックは実装せず、上位コンポーネントに委任
          // 実際のリダイレクトは useAuth フックを使用する側で制御
        }
        
        if (event === 'SIGNED_OUT' && config.loginRoute) {
          // 同様にサインアウト時のリダイレクトも上位で制御
        }
      }
    );

    return () => subscription.unsubscribe();
  }, [supabase, config.defaultRoute, config.loginRoute]);

  // エラーハンドリングヘルパー
  const handleError = (error: any): Error | null => {
    if (error) {
      const errorMessage = error.message || 'エラーが発生しました';
      setError(errorMessage);
      return new Error(errorMessage);
    }
    setError(null);
    return null;
  };

  // サインイン（メール/パスワード）
  const signIn = async (email: string, password: string) => {
    setLoading(true);
    setError(null);
    
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    
    setLoading(false);
    return { error: handleError(error) };
  };

  // サインアップ
  const signUp = async (email: string, password: string, metadata?: Record<string, any>) => {
    setLoading(true);
    setError(null);
    
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata,
        emailRedirectTo: config.redirectUrl
      }
    });
    
    setLoading(false);
    return { error: handleError(error) };
  };

  // マジックリンクサインイン
  const signInWithMagicLink = async (email: string) => {
    setLoading(true);
    setError(null);
    
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: config.redirectUrl
      }
    });
    
    setLoading(false);
    return { error: handleError(error) };
  };

  // OAuth認証
  const signInWithOAuth = async (provider: 'google' | 'github' | 'facebook' | 'twitter') => {
    setLoading(true);
    setError(null);
    
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: config.redirectUrl
      }
    });
    
    setLoading(false);
    return { error: handleError(error) };
  };

  // サインアウト
  const signOut = async () => {
    setLoading(true);
    setError(null);
    
    const { error } = await supabase.auth.signOut();
    
    setLoading(false);
    return { error: handleError(error) };
  };

  // パスワードリセット
  const resetPassword = async (email: string) => {
    setLoading(true);
    setError(null);
    
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: config.redirectUrl
    });
    
    setLoading(false);
    return { error: handleError(error) };
  };

  // プロフィール更新
  const updateProfile = async (updates: { email?: string; password?: string; data?: Record<string, any> }) => {
    setLoading(true);
    setError(null);
    
    const { error } = await supabase.auth.updateUser(updates);
    
    setLoading(false);
    return { error: handleError(error) };
  };

  // エラークリア
  const clearError = () => {
    setError(null);
  };

  const value: AuthContextType = {
    user,
    session,
    loading,
    error,
    signIn,
    signUp,
    signInWithMagicLink,
    signInWithOAuth,
    signOut,
    resetPassword,
    updateProfile,
    clearError
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

/**
 * 認証フック
 * 
 * 認証状態と操作にアクセスするためのフック
 * 
 * @throws {Error} AuthProvider外で使用された場合
 * @returns {AuthContextType} 認証コンテキスト
 */
export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  
  return context;
}

/**
 * 認証ガード用フック
 * 
 * 認証が必要なページで使用し、未認証時に指定されたコンポーネントを表示
 * 
 * @param fallback 未認証時に表示するコンポーネント
 * @returns 認証済みの場合はnull、未認証の場合はfallbackコンポーネント
 */
export function useAuthGuard(fallback?: ReactNode) {
  const { user, loading } = useAuth();
  
  if (loading) {
    return <div className=\"flex items-center justify-center min-h-screen\">読み込み中...</div>;
  }
  
  if (!user) {
    return fallback || <div className=\"flex items-center justify-center min-h-screen\">ログインが必要です</div>;
  }
  
  return null;
}

/**
 * 管理者権限チェック用フック
 */
export function useAdminAuth(adminRole: string = 'admin') {
  const { user } = useAuth();
  
  const isAdmin = user?.user_metadata?.role === adminRole || 
                  user?.app_metadata?.role === adminRole;
  
  return { isAdmin, user };
}

export default AuthContext;