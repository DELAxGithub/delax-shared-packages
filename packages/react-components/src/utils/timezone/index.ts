import { utcToZonedTime } from 'date-fns-tz';
import { startOfDay, parseISO } from 'date-fns';

const JST_TIMEZONE = 'Asia/Tokyo';

/**
 * JST（日本標準時）の今日の日付を取得
 * どのタイムゾーンからアクセスしても日本時間での今日を返す
 * 
 * @returns JST基準の今日のDateオブジェクト
 * 
 * @example
 * ```typescript
 * const today = getJSTToday();
 * console.log(today); // JST基準の今日の日付
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
 * const date = parseJSTDate('2024-01-01');
 * console.log(date); // 2024-01-01をJST基準として解釈したDateオブジェクト
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
 * @param date1 比較する日付1
 * @param date2 比較する日付2
 * @returns date1がdate2より前の場合true
 * 
 * @example
 * ```typescript
 * const isEarlier = isJSTBefore('2024-01-01', '2024-01-02');
 * console.log(isEarlier); // true
 * 
 * const date1 = new Date('2024-01-01');
 * const date2 = new Date('2024-01-02');
 * const isEarlier2 = isJSTBefore(date1, date2);
 * console.log(isEarlier2); // true
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
 * const dateStr = formatJSTDate(new Date());
 * console.log(dateStr); // '2024-01-01' (JST基準)
 * ```
 */
export function formatJSTDate(date: Date): string {
  const jstDate = utcToZonedTime(date, JST_TIMEZONE);
  return jstDate.toISOString().split('T')[0];
}

/**
 * JST タイムゾーン定数
 * 外部で日本標準時を参照する際に使用
 */
export { JST_TIMEZONE };