/**
 * 完パケ納品日を計算する（初回放送日の1週間前の火曜日）
 *
 * 計算ロジック:
 * 1. 初回放送日から1週間前の日付を取得
 * 2. その週の火曜日に設定
 * 3. もし計算された日付が初回放送日より後の場合、さらに1週間前の火曜日に設定
 *
 * @param firstAirDate 初回放送日（YYYY-MM-DD形式）
 * @returns 計算された完パケ納品日（YYYY-MM-DD形式）
 *
 * @example
 * ```typescript
 * // 2024年1月15日（月曜日）が初回放送日の場合
 * const completeDate = calculateCompleteDate('2024-01-15');
 * console.log(completeDate); // '2024-01-09' (1週間前の火曜日)
 *
 * // 2024年1月10日（水曜日）が初回放送日の場合
 * const completeDate2 = calculateCompleteDate('2024-01-10');
 * console.log(completeDate2); // '2024-01-09' (同じ週の火曜日)
 * ```
 */
export declare function calculateCompleteDate(firstAirDate: string): string;
/**
 * PR納品日を計算する（初回放送日の2週間前の月曜日）
 *
 * 計算ロジック:
 * 1. 初回放送日から2週間前の日付を取得
 * 2. その週の月曜日に設定
 * 3. もし計算された日付が初回放送日より後の場合、さらに1週間前の月曜日に設定
 *
 * @param firstAirDate 初回放送日（YYYY-MM-DD形式）
 * @returns 計算されたPR納品日（YYYY-MM-DD形式）
 *
 * @example
 * ```typescript
 * // 2024年1月15日（月曜日）が初回放送日の場合
 * const prDueDate = calculatePrDueDate('2024-01-15');
 * console.log(prDueDate); // '2024-01-01' (2週間前の月曜日)
 *
 * // 2024年1月10日（水曜日）が初回放送日の場合
 * const prDueDate2 = calculatePrDueDate('2024-01-10');
 * console.log(prDueDate2); // '2023-12-25' (2週間前の月曜日)
 * ```
 */
export declare function calculatePrDueDate(firstAirDate: string): string;
/**
 * 業務日計算ユーティリティ
 * メディア制作業界でよく使用される日付計算を提供
 */
export declare const BusinessDateUtils: {
    readonly calculateCompleteDate: typeof calculateCompleteDate;
    readonly calculatePrDueDate: typeof calculatePrDueDate;
};
//# sourceMappingURL=index.d.ts.map