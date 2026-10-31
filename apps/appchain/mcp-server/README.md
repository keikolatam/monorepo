# MCP Server Starknet (Cursor Workspace)

Este servidor MCP expone una herramienta `check_balance` para consultar balance de `ETH` o `STRK` en Starknet.

- **Artículo de referencia**: [Building Your First Starknet MCP Server](https://www.nethermind.io/blog/building-your-first-starknet-mcp-server)

## Redes soportadas
- `mainnet` (por defecto)
- `sepolia`
- **Custom (keikochain/devnet local)** mediante:
  - Variables de entorno: `STARKNET_RPC_URL` + `TOKEN_ETH_ADDRESS` / `TOKEN_STRK_ADDRESS`
  - Overrides por llamada: `rpcUrl`, `tokenAddress`, `decimals`

## Requisitos
- Node.js >= 18.18 (en WSL, no usar npm de Windows)

## Instalación

```bash
cd appchain/mcp-server
npm install
```

## Variables de entorno
- `STARKNET_NETWORK`: `mainnet` (default) o `sepolia`.
- `STARKNET_RPC_URL`: si se define, se usa esta URL (red custom, p.ej. keikochain/devnet) y se pueden definir:
  - `TOKEN_ETH_ADDRESS`, `TOKEN_STRK_ADDRESS` (direcciones ERC-20 en esa red)

## Build y ejecución

```bash
npm run build
npm start
```

## Uso como MCP en Cursor
Agrega este servidor en tu configuración MCP de Cursor.

Ejemplo Keikochain (RPC custom por env):
```json
{
  "mcpServers": {
    "starknet-reader": {
      "command": "node",
      "args": ["/home/kvttvrsis/github/keikolatam/dapp-monorepo/appchain/mcp-server/dist/index.js"],
      "env": {
        "STARKNET_RPC_URL": "https://rpc.keikochain.example",
        "TOKEN_ETH_ADDRESS": "0x...",
        "TOKEN_STRK_ADDRESS": "0x..."
      }
    }
  }
}
```

Ejemplo Devnet local (overrides por llamada):
- `rpcUrl`: `http://127.0.0.1:9945` (según `quick-start.sh`)
- `tokenAddress`: dirección del ERC-20 en tu devnet
- `decimals`: si no es 18, puedes forzarlo

Ejemplo de invocación (parámetros de la herramienta):
```json
{
  "address": "0x0123...abcd",
  "token": "ETH",
  "rpcUrl": "http://127.0.0.1:9945",
  "tokenAddress": "0x0...",
  "decimals": 18
}
```

## Herramienta disponible
- `check_balance`:
  - `address`: dirección en Starknet (0x...)
  - `token`: `ETH` o `STRK`
  - `rpcUrl` (opcional): override de RPC por llamada
  - `tokenAddress` (opcional): override de dirección de token por llamada
  - `decimals` (opcional): override de decimales del token
