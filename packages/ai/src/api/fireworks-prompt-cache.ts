import { calculateCost } from "../models.ts";
import type { Api, AssistantMessage, Model } from "../types.ts";

export interface FireworksPromptCacheUsage {
	promptTokens: number;
	cachedPromptTokens: number;
}

function parseNonNegativeInteger(value: string | undefined): number | undefined {
	if (value === undefined) {
		return undefined;
	}
	const trimmed = value.trim();
	if (!/^\d+$/.test(trimmed)) {
		return undefined;
	}
	const parsed = Number(trimmed);
	return Number.isSafeInteger(parsed) ? parsed : undefined;
}

export function parseFireworksPromptCacheUsage(headers: Record<string, string>): FireworksPromptCacheUsage | undefined {
	const promptTokens = parseNonNegativeInteger(headers["fireworks-prompt-tokens"]);
	const cachedPromptTokens = parseNonNegativeInteger(headers["fireworks-cached-prompt-tokens"]);
	if (promptTokens === undefined || cachedPromptTokens === undefined) {
		return undefined;
	}
	return {
		promptTokens,
		cachedPromptTokens: Math.min(cachedPromptTokens, promptTokens),
	};
}

export function applyFireworksPromptCacheUsage<TApi extends Api>(
	model: Model<TApi>,
	usage: AssistantMessage["usage"],
	cacheUsage: FireworksPromptCacheUsage | undefined,
): void {
	if (!cacheUsage) {
		return;
	}
	usage.input = Math.max(0, cacheUsage.promptTokens - cacheUsage.cachedPromptTokens);
	usage.cacheRead = cacheUsage.cachedPromptTokens;
	usage.totalTokens = usage.input + usage.output + usage.cacheRead + usage.cacheWrite;
	calculateCost(model, usage);
}
