import { utcToZonedTime } from 'date-fns-tz';
import { startOfDay, parseISO } from 'date-fns';

/**
 * 日本標準時（JST）基準の日付処理ユーティリティ
 * 企業システムで確実に日本時間ベースの処理を行うためのヘルパー関数群
 */

const JST_TIMEZONE = 'Asia/Tokyo';

/**
 * JST（日本標準時）の今日の日付を取得
 * どのタイムゾーンからアクセスしても日本時間での今日を返す
 * 
 * @returns JST基準の今日の日付（00:00:00）
 * 
 * @example
 * ```typescript
 * const today = getJSTToday();
 * console.log(today); // 2025-08-03T00:00:00.000Z (JSTの2025-08-03 00:00)
 * ```
 */
export function getJSTToday(): Date {
  const now = new Date();
  const jstNow = utcToZonedTime(now, JST_TIMEZONE);
  return startOfDay(jstNow);
}

/**
 * 日付文字列（YYYY-MM-DD）をJST基準の日付として解釈
 * 
 * @param dateStr YYYY-MM-DD形式の日付文字列
 * @returns JST基準のDateオブジェクト
 * 
 * @example
 * ```typescript
 * const date = parseJSTDate('2025-08-03');
 * console.log(date); // JST基準の2025-08-03を表すDateオブジェクト
 * ```
 */
export function parseJSTDate(dateStr: string): Date {
  // 日付文字列をそのまま解釈（タイムゾーンの影響を受けない）
  const parsedDate = parseISO(dateStr);
  // JST基準として扱う
  return utcToZonedTime(parsedDate, JST_TIMEZONE);
}

/**
 * 2つの日付をJST基準で比較
 * 
 * @param date1 比較する日付1（Date | YYYY-MM-DD文字列）
 * @param date2 比較する日付2（Date | YYYY-MM-DD文字列）
 * @returns date1がdate2より前の場合true
 * 
 * @example
 * ```typescript
 * const isBefore = isJSTBefore('2025-08-01', '2025-08-03');
 * console.log(isBefore); // true
 * 
 * const isAfter = isJSTBefore(new Date('2025-08-05'), '2025-08-03');
 * console.log(isAfter); // false
 * ```
 */
export function isJSTBefore(date1: Date | string, date2: Date | string): boolean {
  const jstDate1 = typeof date1 === 'string' ? parseJSTDate(date1) : utcToZonedTime(date1, JST_TIMEZONE);
  const jstDate2 = typeof date2 === 'string' ? parseJSTDate(date2) : utcToZonedTime(date2, JST_TIMEZONE);
  return jstDate1 < jstDate2;
}

/**
 * JST基準での日付文字列（YYYY-MM-DD）を取得
 * 
 * @param date 変換する日付
 * @returns YYYY-MM-DD形式の文字列
 * 
 * @example
 * ```typescript
 * const formatted = formatJSTDate(new Date());
 * console.log(formatted); // "2025-08-03" (JST基準)
 * ```
 */
export function formatJSTDate(date: Date): string {
  const jstDate = utcToZonedTime(date, JST_TIMEZONE);
  return jstDate.toISOString().split('T')[0];
}

/**
 * JST現在時刻を取得
 * 
 * @returns JST基準の現在日時
 * 
 * @example
 * ```typescript
 * const now = getJSTNow();
 * console.log(now); // JST基準の現在日時
 * ```
 */
export function getJSTNow(): Date {
  return utcToZonedTime(new Date(), JST_TIMEZONE);
}

/**
 * JST基準での時刻付き文字列を取得（YYYY-MM-DD HH:mm:ss）
 * 
 * @param date 変換する日付
 * @returns YYYY-MM-DD HH:mm:ss形式の文字列
 * 
 * @example
 * ```typescript
 * const formatted = formatJSTDateTime(new Date());
 * console.log(formatted); // "2025-08-03 15:30:45"
 * ```
 */
export function formatJSTDateTime(date: Date): string {
  const jstDate = utcToZonedTime(date, JST_TIMEZONE);
  return jstDate.toISOString().replace('T', ' ').slice(0, 19);
}