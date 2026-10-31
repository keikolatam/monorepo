import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
	CallToolRequestSchema,
	ListToolsRequestSchema,
	Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { RpcProvider, ProviderInterface, uint256, Contract } from "starknet";

// Config de red: mainnet/sepolia o RPC custom via env
const STARKNET_NETWORK = (process.env.STARKNET_NETWORK || "mainnet").toLowerCase();
const STARKNET_RPC_URL = process.env.STARKNET_RPC_URL || "";

function createProviderFromUrl(url: string): ProviderInterface {
	return new RpcProvider({ nodeUrl: url });
}

function createDefaultProvider(): ProviderInterface {
	if (STARKNET_RPC_URL) {
		return createProviderFromUrl(STARKNET_RPC_URL);
	}
	if (STARKNET_NETWORK === "testnet" || STARKNET_NETWORK === "sepolia") {
		return createProviderFromUrl("https://rpc.sepolia.starknet.io");
	}
	return createProviderFromUrl("https://rpc.starknet.io");
}

const defaultProvider = createDefaultProvider();

// Direcciones de tokens: usar env si hay RPC custom
const ENV_TOKEN_ADDRESSES: Record<string, string | undefined> = {
	ETH: process.env.TOKEN_ETH_ADDRESS,
	STRK: process.env.TOKEN_STRK_ADDRESS,
};

const TOKEN_ADDRESSES: Record<string, Record<string, string>> = {
	mainnet: {
		ETH: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
		STRK: "0x04718f5e407e2fd6f3d6de0c217d5a67b9c3b66c7a2a63a4d0c42e9565a83e0f",
	},
	sepolia: {
		ETH: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
		STRK: "0x050b9c3b6f400e1bfea33c5d5ea34466216c0daac82466e0e5c5c1f15c8e5c5b",
	},
};

function isValidStarknetAddress(address: string): boolean {
	return /^0x[0-9a-fA-F]{1,64}$/.test(address);
}

async function getTokenDecimalsDefault(token: "ETH" | "STRK"): Promise<number> {
	return 18;
}

async function resolveTokenAddress(
	token: "ETH" | "STRK",
	options?: { rpcUrlOverride?: string; tokenAddressOverride?: string }
): Promise<{ networkLabel: string; address: string }> {
	if (options?.tokenAddressOverride) {
		return { networkLabel: options.rpcUrlOverride ? "custom" : "override", address: options.tokenAddressOverride };
	}
	if (options?.rpcUrlOverride || STARKNET_RPC_URL) {
		const envAddress = ENV_TOKEN_ADDRESSES[token];
		if (!envAddress) {
			throw new Error(`TOKEN_${token}_ADDRESS no está definido para la red custom (STARKNET_RPC_URL o rpcUrl override)`);
		}
		return { networkLabel: "custom", address: envAddress };
	}
	const networkKey = STARKNET_NETWORK === "sepolia" || STARKNET_NETWORK === "testnet" ? "sepolia" : "mainnet";
	return { networkLabel: networkKey, address: TOKEN_ADDRESSES[networkKey][token] };
}

async function checkBalance(
	address: string,
	token: "ETH" | "STRK",
	options?: { rpcUrlOverride?: string; tokenAddressOverride?: string; decimalsOverride?: number }
) {
	const provider: ProviderInterface = options?.rpcUrlOverride
		? createProviderFromUrl(options.rpcUrlOverride)
		: defaultProvider;
	const { networkLabel, address: tokenAddress } = await resolveTokenAddress(token, {
		rpcUrlOverride: options?.rpcUrlOverride,
		tokenAddressOverride: options?.tokenAddressOverride,
	});
	const erc20Abi = [
		{
			name: "balanceOf",
			type: "function",
			inputs: [{ name: "account", type: "felt" }],
			outputs: [{ name: "balance", type: "Uint256" }],
		},
	];
	const contract = new Contract(erc20Abi as any, tokenAddress, provider);
	const raw = await contract.balanceOf(address);
	const asUint256 = (raw as any).balance ?? raw;
	const balance = uint256.uint256ToBN(asUint256);
	const decimals = typeof options?.decimalsOverride === "number" ? options.decimalsOverride : await getTokenDecimalsDefault(token);
	const human = Number(balance.toString()) / 10 ** decimals;
	return {
		network: networkLabel,
		rpcUrl: options?.rpcUrlOverride || STARKNET_RPC_URL || undefined,
		address,
		token,
		tokenAddress,
		balanceRaw: balance.toString(),
		decimals,
		balance: human,
	};
}

const server = new Server(
	{
		name: "starknet-reader",
		version: "0.1.0",
	},
	{ capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
	const tools: Tool[] = [
		{
			name: "check_balance",
			description:
				"Obtiene el balance de ETH/STRK para una dirección en Starknet. Redes: mainnet, sepolia o custom. Puedes usar env STARKNET_RPC_URL + TOKEN_ETH_ADDRESS/TOKEN_STRK_ADDRESS o pasar overrides por llamada.",
			inputSchema: {
				type: "object",
				properties: {
					address: {
						type: "string",
						description: "Dirección de cuenta en Starknet (0x...)",
					},
					token: {
						type: "string",
						description: "Símbolo del token: ETH o STRK",
						enum: ["ETH", "STRK"],
					},
					rpcUrl: {
						type: "string",
						description: "Override de RPC para esta llamada (p.ej., http://127.0.0.1:9945)",
					},
					tokenAddress: {
						type: "string",
						description: "Dirección ERC-20 del token en la red indicada (override por llamada)",
					},
					decimals: {
						type: "number",
						description: "Decimales del token (override por llamada; default 18)",
					}
				},
				required: ["address", "token"],
			},
		},
	];
	return { tools };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
	const { name, arguments: args } = request.params;
	if (name !== "check_balance") {
		throw new Error(`Unknown tool: ${name}`);
	}

	try {
		const address = String((args as any)?.address ?? "");
		const token = String((args as any)?.token ?? "").toUpperCase();
		const rpcUrlOverride = (args as any)?.rpcUrl ? String((args as any).rpcUrl) : undefined;
		const tokenAddressOverride = (args as any)?.tokenAddress ? String((args as any).tokenAddress) : undefined;
		const decimalsOverride = (args as any)?.decimals !== undefined ? Number((args as any).decimals) : undefined;

		if (!address) throw new Error("Address is required");
		if (!token) throw new Error("Token is required");
		if (!isValidStarknetAddress(address)) throw new Error("Invalid Starknet address");
		if (token !== "ETH" && token !== "STRK") throw new Error("Supported tokens: ETH, STRK");

		const result = await checkBalance(address, token as "ETH" | "STRK", {
			rpcUrlOverride,
			tokenAddressOverride,
			decimalsOverride,
		});
		return {
			content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
		};
	} catch (error) {
		const errorMessage = error instanceof Error ? error.message : "Unknown error";
		return {
			content: [{ type: "text", text: `Error: ${errorMessage}` }],
			isError: true,
		};
	}
});

async function main() {
	const transport = new StdioServerTransport();
	await server.connect(transport);
	console.error("Starknet Reader MCP Server running");
}

main().catch((error) => {
	console.error("Fatal error:", error);
	process.exit(1);
});
