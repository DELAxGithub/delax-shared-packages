import { subWeeks, setDay, addDays, subDays } from 'date-fns';
import { formatJSTDate } from './timezone';

/**
 * 放送・制作業界向け日程計算ユーティリティ
 * 
 * 放送業界特有の納期計算（完パケ、PR、試写等）を標準化
 * 設定可能なパラメータで様々な制作フローに対応
 */

export interface DeliveryConfig {
  /** 完パケ納品設定 */
  finalPackage: {
    /** 放送日から何週間前か */
    weeksBeforeAir: number;
    /** 何曜日に設定するか（0=日曜, 1=月曜, 2=火曜...） */
    dayOfWeek: number;
  };
  /** PR納品設定 */
  promotional: {
    /** 放送日から何週間前か */
    weeksBeforeAir: number;
    /** 何曜日に設定するか */
    dayOfWeek: number;
  };
  /** 試写設定 */
  preview?: {
    /** 完パケ納品から何日後か */
    daysAfterFinalPackage: number;
  };
}

/** デフォルト設定（PMliberary実績ベース） */
export const DEFAULT_DELIVERY_CONFIG: DeliveryConfig = {
  finalPackage: {
    weeksBeforeAir: 1,  // 1週間前
    dayOfWeek: 2,       // 火曜日
  },
  promotional: {
    weeksBeforeAir: 2,  // 2週間前
    dayOfWeek: 1,       // 月曜日
  },
  preview: {
    daysAfterFinalPackage: 2,  // 完パケ2日後
  }
};

/**
 * 完パケ納品日を計算する
 * 
 * @param firstAirDate 初回放送日（YYYY-MM-DD）
 * @param config 納期設定（省略時はデフォルト）
 * @returns 計算された完パケ納品日（YYYY-MM-DD）
 * 
 * @example
 * ```typescript
 * // デフォルト設定（1週間前の火曜日）
 * const completeDate = calculateCompleteDate('2025-08-15');
 * console.log(completeDate); // "2025-08-05"
 * 
 * // カスタム設定（2週間前の木曜日）
 * const customDate = calculateCompleteDate('2025-08-15', {
 *   finalPackage: { weeksBeforeAir: 2, dayOfWeek: 4 }
 * });
 * ```
 */
export function calculateCompleteDate(
  firstAirDate: string, 
  config: Partial<DeliveryConfig> = {}
): string {
  const settings = {
    ...DEFAULT_DELIVERY_CONFIG,
    ...config,
    finalPackage: {
      ...DEFAULT_DELIVERY_CONFIG.finalPackage,
      ...config.finalPackage
    }
  };

  // 文字列をJST基準のDateオブジェクトに変換
  const airDate = new Date(firstAirDate + 'T00:00:00');
  
  // 指定週数前の日付を取得
  let completeDate = subWeeks(airDate, settings.finalPackage.weeksBeforeAir);
  
  // 指定曜日に設定
  completeDate = setDay(completeDate, settings.finalPackage.dayOfWeek);
  
  // もし計算された日付が初回放送日以降の場合、さらに1週間前に調整
  if (completeDate >= airDate) {
    completeDate = subWeeks(completeDate, 1);
  }
  
  return formatJSTDate(completeDate);
}

/**
 * PR納品日を計算する
 * 
 * @param firstAirDate 初回放送日（YYYY-MM-DD）
 * @param config 納期設定（省略時はデフォルト）
 * @returns 計算されたPR納品日（YYYY-MM-DD）
 * 
 * @example
 * ```typescript
 * // デフォルト設定（2週間前の月曜日）
 * const prDate = calculatePrDueDate('2025-08-15');
 * console.log(prDate); // "2025-07-28"
 * 
 * // カスタム設定（3週間前の金曜日）
 * const customPrDate = calculatePrDueDate('2025-08-15', {
 *   promotional: { weeksBeforeAir: 3, dayOfWeek: 5 }
 * });
 * ```
 */
export function calculatePrDueDate(
  firstAirDate: string, 
  config: Partial<DeliveryConfig> = {}
): string {
  const settings = {
    ...DEFAULT_DELIVERY_CONFIG,
    ...config,
    promotional: {
      ...DEFAULT_DELIVERY_CONFIG.promotional,
      ...config.promotional
    }
  };

  // 文字列をJST基準のDateオブジェクトに変換
  const airDate = new Date(firstAirDate + 'T00:00:00');
  
  // 指定週数前の日付を取得
  let prDueDate = subWeeks(airDate, settings.promotional.weeksBeforeAir);
  
  // 指定曜日に設定
  prDueDate = setDay(prDueDate, settings.promotional.dayOfWeek);
  
  // もし計算された日付が初回放送日以降の場合、さらに1週間前に調整
  if (prDueDate >= airDate) {
    prDueDate = subWeeks(prDueDate, 1);
  }
  
  return formatJSTDate(prDueDate);
}

/**
 * 試写日を計算する（完パケ納品日ベース）
 * 
 * @param completeDate 完パケ納品日（YYYY-MM-DD）
 * @param config 納期設定（省略時はデフォルト）
 * @returns 計算された試写日（YYYY-MM-DD）
 * 
 * @example
 * ```typescript
 * const previewDate = calculatePreviewDate('2025-08-05');
 * console.log(previewDate); // "2025-08-07" (2日後)
 * ```
 */
export function calculatePreviewDate(
  completeDate: string,
  config: Partial<DeliveryConfig> = {}
): string {
  const settings = {
    ...DEFAULT_DELIVERY_CONFIG,
    ...config,
    preview: {
      ...DEFAULT_DELIVERY_CONFIG.preview,
      ...config.preview
    }
  };

  if (!settings.preview) {
    throw new Error('Preview configuration is required');
  }

  const packageDate = new Date(completeDate + 'T00:00:00');
  const previewDate = addDays(packageDate, settings.preview.daysAfterFinalPackage);
  
  return formatJSTDate(previewDate);
}

/**
 * 収録日を計算する（完パケ納品日から逆算）
 * 
 * @param completeDate 完パケ納品日（YYYY-MM-DD）
 * @param processingDays 編集・MA等の処理日数
 * @returns 推奨収録日（YYYY-MM-DD）
 * 
 * @example
 * ```typescript
 * const recordingDate = calculateRecordingDate('2025-08-05', 10);
 * console.log(recordingDate); // "2025-07-26" (10日前)
 * ```
 */
export function calculateRecordingDate(
  completeDate: string,
  processingDays: number = 10
): string {
  const packageDate = new Date(completeDate + 'T00:00:00');
  const recordingDate = subDays(packageDate, processingDays);
  
  return formatJSTDate(recordingDate);
}

/**
 * 制作スケジュール全体を計算する
 * 
 * @param firstAirDate 初回放送日（YYYY-MM-DD）
 * @param config 納期設定
 * @param processingDays 編集処理日数
 * @returns 制作スケジュール全体
 * 
 * @example
 * ```typescript
 * const schedule = calculateProductionSchedule('2025-08-15');
 * console.log(schedule);
 * // {
 * //   airDate: '2025-08-15',
 * //   finalPackageDate: '2025-08-05',
 * //   prDueDate: '2025-07-28',
 * //   previewDate: '2025-08-07',
 * //   recommendedRecordingDate: '2025-07-26'
 * // }
 * ```
 */
export function calculateProductionSchedule(
  firstAirDate: string,
  config: Partial<DeliveryConfig> = {},
  processingDays: number = 10
) {
  const finalPackageDate = calculateCompleteDate(firstAirDate, config);
  const prDueDate = calculatePrDueDate(firstAirDate, config);
  const previewDate = config.preview ? calculatePreviewDate(finalPackageDate, config) : null;
  const recommendedRecordingDate = calculateRecordingDate(finalPackageDate, processingDays);

  return {
    airDate: firstAirDate,
    finalPackageDate,
    prDueDate,
    previewDate,
    recommendedRecordingDate,
    processingDays,
    config: {
      ...DEFAULT_DELIVERY_CONFIG,
      ...config
    }
  };
}