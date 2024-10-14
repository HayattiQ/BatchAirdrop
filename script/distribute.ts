import fs from 'fs';
import csv from 'csv-parser';
import dotenv from 'dotenv';

// Import the ABI from a JSON file
import contractABI from './abi.json';
import { parseEther } from 'viem';
import { account, publicClient, walletClient } from './client';

// Load environment variables
dotenv.config();

const initialNonce = 16;
const numCalls = 1;

async function loopDistribute() {
  for (let i = initialNonce; i < initialNonce + numCalls; i++) {
    try {
        await callContract(i);
        console.log(`Completed call for nonce ${i}`);
      } catch (error) {
        console.error(`Error in call for nonce ${i}:`, error);
        break;
      }
    }
}

async function callContract(nonce: number) {
  const contractAddress = process.env.CONTRACT_ADDRESS;

  if ( !contractAddress ) {
    throw new Error('Missing environment variables. Please check your .env file.');
  }
    const {request} = await publicClient.simulateContract({
      account,
      address: contractAddress as `0x${string}`,
      functionName: "distribute",
      nonce,
      abi: contractABI
    });

    const hash = await walletClient.writeContract(request)

    console.log('Transaction sent:', hash);

    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    console.log('Transaction successful:', receipt.transactionHash);

}

// Execute the function
loopDistribute();