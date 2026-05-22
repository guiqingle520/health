import { Injectable } from '@nestjs/common';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateMyDietRecordDto } from './dto/create-my-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateMyExerciseRecordDto } from './dto/create-my-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { GetDietRecordHistoryQueryDto } from './dto/get-diet-record-history-query.dto';
import { GetExerciseRecordHistoryQueryDto } from './dto/get-exercise-record-history-query.dto';
import { GetHealthTrendQueryDto } from './dto/get-health-trend-query.dto';
import { GetRecordHistoryQueryDto } from './dto/get-record-history-query.dto';
import { UpsertMyProfileDto } from './dto/upsert-my-profile.dto';
import {
  AiRecommendationTodayView,
  DailySummary,
  DashboardView,
  DietRecordHistoryItem,
  ExerciseRecordHistoryItem,
  HealthTrendPeriod,
  HealthTrendView,
  ProfileCenterView,
} from './interfaces/health.types';
import { HealthRepository } from './health.repository';

@Injectable()
export class HealthService {
  constructor(private readonly healthRepository: HealthRepository) {}

  saveProfile(payload: CreateProfileDto): Promise<CreateProfileDto> {
    return this.healthRepository.upsertProfile(payload.id, {
      nickname: payload.nickname,
      age: payload.age,
      gender: payload.gender,
      heightCm: payload.heightCm,
      weightKg: payload.weightKg,
      goal: payload.goal,
    });
  }

  upsertMyProfile(
    userId: string,
    payload: UpsertMyProfileDto,
  ): Promise<CreateProfileDto> {
    return this.healthRepository.upsertProfile(userId, payload);
  }

  getProfile(userId: string): Promise<CreateProfileDto | undefined> {
    return this.healthRepository.findProfileByUserId(userId);
  }

  async getDashboard(userId: string, date: string): Promise<DashboardView> {
    const summary = await this.getDailySummary(userId, date);
    const profile = await this.getProfile(userId);
    const healthScore = this.calculateHealthScore(summary);

    return {
      date,
      healthScore,
      profile: profile
        ? {
            nickname: profile.nickname,
            goal: profile.goal,
          }
        : null,
      cards: {
        steps: 8234,
        stepTarget: 10000,
        sleepHours: 7.2,
        sleepScore: 85,
        waterMl: 1200,
        waterTargetMl: 2000,
        calories: summary.intake.calories,
        calorieTarget: 2200,
      },
      aiInsights: this.buildInsights(summary),
      summary,
    };
  }

  async getDietRecordHistory(
    userId: string,
    query: GetDietRecordHistoryQueryDto,
  ): Promise<DietRecordHistoryItem[]> {
    const { from, to, limit } = this.normalizeHistoryQuery(query);
    return this.healthRepository.findDietRecordsByUserIdAndDateRange(
      userId,
      from,
      to,
      limit,
      query.mealType,
    );
  }

  async getExerciseRecordHistory(
    userId: string,
    query: GetExerciseRecordHistoryQueryDto,
  ): Promise<ExerciseRecordHistoryItem[]> {
    const { from, to, limit } = this.normalizeHistoryQuery(query);
    return this.healthRepository.findExerciseRecordsByUserIdAndDateRange(
      userId,
      from,
      to,
      limit,
      query.exerciseType,
    );
  }

  addDietRecord(
    payload: CreateDietRecordDto,
  ): Promise<CreateDietRecordDto & { id: string; date: string }> {
    const date = new Date().toISOString().slice(0, 10);
    return this.healthRepository.insertDietRecord(payload, date);
  }

  addMyDietRecord(
    userId: string,
    payload: CreateMyDietRecordDto,
  ): Promise<CreateDietRecordDto & { id: string; date: string }> {
    return this.addDietRecord({
      userId,
      mealType: payload.mealType,
      foodName: payload.foodName,
      nutrition: payload.nutrition,
    });
  }

  addExerciseRecord(
    payload: CreateExerciseRecordDto,
  ): Promise<CreateExerciseRecordDto & { id: string; date: string }> {
    const date = new Date().toISOString().slice(0, 10);
    return this.healthRepository.insertExerciseRecord(payload, date);
  }

  addMyExerciseRecord(
    userId: string,
    payload: CreateMyExerciseRecordDto,
  ): Promise<CreateExerciseRecordDto & { id: string; date: string }> {
    return this.addExerciseRecord({
      userId,
      exerciseType: payload.exerciseType,
      durationMinutes: payload.durationMinutes,
      caloriesBurned: payload.caloriesBurned,
    });
  }

  async getDietRecordDetail(
    userId: string,
    id: string,
  ): Promise<DietRecordHistoryItem | undefined> {
    return this.healthRepository.findDietRecordById(userId, id);
  }

  async getExerciseRecordDetail(
    userId: string,
    id: string,
  ): Promise<ExerciseRecordHistoryItem | undefined> {
    return this.healthRepository.findExerciseRecordById(userId, id);
  }

  async deleteDietRecord(userId: string, id: string): Promise<{ success: true } | undefined> {
    const deleted = await this.healthRepository.deleteDietRecordById(userId, id);
    return deleted ? { success: true } : undefined;
  }

  async deleteExerciseRecord(
    userId: string,
    id: string,
  ): Promise<{ success: true } | undefined> {
    const deleted = await this.healthRepository.deleteExerciseRecordById(userId, id);
    return deleted ? { success: true } : undefined;
  }

  async getDailySummary(userId: string, date: string): Promise<DailySummary> {
    const [intake, burnedCalories] = await Promise.all([
      this.healthRepository.getDailyNutritionTotals(userId, date),
      this.healthRepository.getDailyBurnedCalories(userId, date),
    ]);

    return {
      date,
      intake,
      burnedCalories,
      suggestion:
        intake.protein < 60
          ? '今日蛋白质偏低，建议补充鸡蛋、鱼类或豆制品。'
          : '营养结构较均衡，继续保持。',
    };
  }

  async getTrend(
    userId: string,
    query: GetHealthTrendQueryDto,
  ): Promise<HealthTrendView> {
    const metric = query.metric ?? 'weight';
    const period = query.period ?? 'week';
    const today = new Date().toISOString().slice(0, 10);
    const [profile, dashboard] = await Promise.all([
      this.getProfile(userId),
      this.getDashboard(userId, today),
    ]);

    const currentValue = this.getTrendCurrentValue(metric, profile, dashboard);
    const pointCount = this.getTrendPointCount(period);
    const step = this.getTrendStep(metric, period);
    const points = Array.from({ length: pointCount }, (_, index) => {
      const date = new Date(`${today}T00:00:00.000Z`);
      date.setUTCDate(date.getUTCDate() - (pointCount - 1 - index));
      return {
        date: date.toISOString().slice(0, 10),
        value: Number((currentValue - step * (pointCount - 1 - index)).toFixed(1)),
      };
    });
    const delta = Number((points.at(-1)!.value - points[0].value).toFixed(1));

    return {
      metric,
      period,
      currentValue,
      delta,
      unit: this.getTrendUnit(metric),
      points,
      signals: [
        {
          level: metric === 'heartRate' ? 'warning' : 'info',
          message: this.getTrendSignal(metric, period, delta),
        },
      ],
    };
  }

  async getTodayRecommendations(
    userId: string,
    date = new Date().toISOString().slice(0, 10),
  ): Promise<AiRecommendationTodayView> {
    const summary = await this.getDailySummary(userId, date);

    return {
      date,
      items: [
        summary.intake.protein < 60
          ? {
              id: `${date}:protein`,
              type: 'diet',
              title: '晚餐补充优质蛋白',
              reason: '今日蛋白质摄入低于 60g，建议加入鱼类、鸡蛋或豆制品。',
              actionText: '记录晚餐',
              status: 'pending',
            }
          : {
              id: `${date}:diet-balance`,
              type: 'diet',
              title: '保持当前饮食结构',
              reason: '本日蛋白质摄入达标，营养结构较均衡。',
              actionText: '查看记录',
              status: 'pending',
            },
        summary.burnedCalories < 250
          ? {
              id: `${date}:activity`,
              type: 'exercise',
              title: '增加 20 分钟轻有氧',
              reason: '今日运动消耗较少，适合增加散步、骑行或低强度有氧活动。',
              actionText: '记录运动',
              status: 'pending',
            }
          : {
              id: `${date}:recovery`,
              type: 'sleep',
              title: '保持恢复节奏',
              reason: '今日运动量表现良好，睡前放松有助于恢复。',
              actionText: '设置提醒',
              status: 'pending',
            },
        {
          id: `${date}:water`,
          type: 'water',
          title: '分次补水 800ml',
          reason: '今日目标饮水 2L，建议下午和晚餐前分次补充。',
          actionText: '记录喝水',
          status: 'pending',
        },
      ],
    };
  }

  async getProfileCenter(
    userId: string,
    date = new Date().toISOString().slice(0, 10),
  ): Promise<ProfileCenterView | undefined> {
    const [profile, dashboard] = await Promise.all([
      this.getProfile(userId),
      this.getDashboard(userId, date),
    ]);
    if (!profile) {
      return undefined;
    }

    return {
      profile: {
        nickname: profile.nickname,
        goal: profile.goal,
        goalLabel: this.getGoalLabel(profile.goal),
      },
      stats: {
        healthScore: dashboard.healthScore,
        streakDays: 7,
        reportCount: 2,
        connectedDevices: 0,
      },
      pro: {
        enabled: false,
        title: 'HealthGuard Pro',
        subtitle: '解锁深度报告、设备同步和家庭共享',
      },
      sections: [
        { id: 'profile', title: '健康档案', subtitle: '基础资料、目标、风险标签' },
        { id: 'reports', title: '数据与报告', subtitle: '周报、月报和导出能力' },
        { id: 'devices', title: '设备与数据源', subtitle: 'Garmin 未连接 · 即将支持' },
        { id: 'family', title: '家庭共享', subtitle: '家人授权与陪伴视角' },
        { id: 'preferences', title: '隐私与提醒', subtitle: '提醒、隐私和单位设置' },
        { id: 'support', title: '帮助与反馈', subtitle: '常见问题与反馈入口' },
      ],
    };
  }

  private calculateHealthScore(summary: DailySummary): number {
    const proteinScore = Math.min(summary.intake.protein / 80, 1) * 25;
    const fiberScore = Math.min(summary.intake.fiber / 25, 1) * 20;
    const activityScore = Math.min(summary.burnedCalories / 600, 1) * 30;
    const calorieBalanceScore =
      summary.intake.calories <= 2200 && summary.intake.calories >= 1200
        ? 25
        : 10;

    return Math.round(
      Math.max(
        0,
        Math.min(
          proteinScore + fiberScore + activityScore + calorieBalanceScore,
          100,
        ),
      ),
    );
  }

  private normalizeHistoryQuery(query: GetRecordHistoryQueryDto): {
    from: string;
    to: string;
    limit: number;
  } {
    const today = new Date().toISOString().slice(0, 10);
    const to = query.to ?? today;
    const endDate = new Date(`${to}T00:00:00.000Z`);
    const defaultFromDate = new Date(endDate);
    defaultFromDate.setUTCDate(defaultFromDate.getUTCDate() - 29);

    const from = query.from ?? defaultFromDate.toISOString().slice(0, 10);
    const limit = Math.min(query.limit ?? 50, 100);

    return {
      from,
      to,
      limit,
    };
  }

  private getTrendCurrentValue(
    metric: HealthTrendView['metric'],
    profile: CreateProfileDto | undefined,
    dashboard: DashboardView,
  ): number {
    switch (metric) {
      case 'weight':
        return profile?.weightKg ?? 70;
      case 'score':
        return dashboard.healthScore;
      case 'heartRate':
        return 76;
      case 'calories':
        return dashboard.summary.intake.calories;
      case 'water':
        return dashboard.cards.waterMl;
      case 'sleep':
        return dashboard.cards.sleepHours;
    }
  }

  private getTrendPointCount(period: HealthTrendPeriod): number {
    switch (period) {
      case 'week':
        return 7;
      case 'month':
        return 12;
      case 'year':
        return 12;
    }
  }

  private getTrendStep(metric: HealthTrendView['metric'], period: HealthTrendPeriod): number {
    const periodScale = period === 'week' ? 1 : period === 'month' ? 1.6 : 2.4;
    switch (metric) {
      case 'weight':
        return -0.15 * periodScale;
      case 'score':
        return 0.8 * periodScale;
      case 'heartRate':
        return 0.4 * periodScale;
      case 'calories':
        return 18 * periodScale;
      case 'water':
        return 35 * periodScale;
      case 'sleep':
        return 0.04 * periodScale;
    }
  }

  private getTrendUnit(metric: HealthTrendView['metric']): string {
    switch (metric) {
      case 'weight':
        return 'kg';
      case 'score':
        return '分';
      case 'heartRate':
        return 'bpm';
      case 'calories':
        return 'kcal';
      case 'water':
        return 'ml';
      case 'sleep':
        return 'h';
    }
  }

  private getTrendSignal(
    metric: HealthTrendView['metric'],
    period: HealthTrendPeriod,
    delta: number,
  ): string {
    const periodLabel = period === 'week' ? '本周' : period === 'month' ? '本月' : '今年';
    switch (metric) {
      case 'weight':
        return `${periodLabel}体重变化 ${delta.toFixed(1)}kg，继续关注饮食和运动节奏。`;
      case 'score':
        return `${periodLabel}健康分变化 ${delta.toFixed(1)}分，整体趋势平稳。`;
      case 'heartRate':
        return `${periodLabel}静息心率有波动，建议结合睡眠和运动恢复观察。`;
      case 'calories':
        return `${periodLabel}热量摄入变化 ${delta.toFixed(1)}kcal，注意保持均衡。`;
      case 'water':
        return `${periodLabel}饮水变化 ${delta.toFixed(1)}ml，建议分时段补水。`;
      case 'sleep':
        return `${periodLabel}睡眠变化 ${delta.toFixed(1)}h，睡前放松有助于恢复。`;
    }
  }

  private getGoalLabel(goal: CreateProfileDto['goal']): string {
    switch (goal) {
      case 'lose_fat':
        return '减脂';
      case 'gain_muscle':
        return '增肌';
      case 'maintain':
        return '保持健康';
    }
  }

  private buildInsights(summary: DailySummary): string[] {
    const insights: string[] = [];

    if (summary.intake.protein < 60) {
      insights.push('今日蛋白质偏低，建议补充鸡蛋、鱼类或豆制品。');
    } else {
      insights.push('本日蛋白质摄入达标，保持当前饮食结构。');
    }

    if (summary.burnedCalories < 250) {
      insights.push('运动消耗较少，建议增加 20-30 分钟有氧活动。');
    } else {
      insights.push('今日运动量表现良好，继续保持。');
    }

    return insights;
  }
}
