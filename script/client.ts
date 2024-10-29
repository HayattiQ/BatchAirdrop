import { createPublicClient, http, createWalletClient } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { base } from "viem/chains";
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const baseRpcUrl = process.env.RPC_URL;
const privateKey = process.env.PRIVATE_KEY;

if (!baseRpcUrl  || !privateKey ) {
    throw new Error('Missing environment variables. Please check your .env file.');
  }


  // Setup Viem clients for Base chain
export const publicClient = createPublicClient({
    chain: base,
    transport: http(baseRpcUrl)
  });

export const account = privateKeyToAccount(`0x${privateKey}`);

export const walletClient = createWalletClient({
    account,
    chain: base,
    transport: http(baseRpcUrl)
  });
