import fs from 'fs';
import csv from 'csv-parser';
import { createPublicClient, createWalletClient, http, parseEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { base } from 'viem/chains';
import dotenv from 'dotenv';

// Import the ABI from a JSON file
import contractABI from './abi.json';

// Load environment variables
dotenv.config();

interface CsvRow {
  address: string;
  amount: string;
}

async function processCsvAndCallContract() {
  // Retrieve environment variables
  const baseRpcUrl = process.env.BASE_RPC_URL;
  const contractAddress = process.env.CONTRACT_ADDRESS;
  const privateKey = process.env.PRIVATE_KEY;
  const csvFilePath = process.env.CSV_FILE_PATH;

  if (!baseRpcUrl || !contractAddress || !privateKey || !csvFilePath) {
    throw new Error('Missing environment variables. Please check your .env file.');
  }

  // Setup Viem clients for Base chain
  const publicClient = createPublicClient({
    chain: base,
    transport: http(baseRpcUrl)
  });

  const account = privateKeyToAccount(`0x${privateKey}`);

  const walletClient = createWalletClient({
    account,
    chain: base,
    transport: http(baseRpcUrl)
  });

  const wallets: `0x${string}`[] = [];
  const amounts: bigint[] = [];

  await new Promise<void>((resolve, reject) => {
    fs.createReadStream(csvFilePath)
      .pipe(csv())
      .on('data', (row: CsvRow) => {
        console.log(row)
        wallets.push(row.address as `0x${string}`);
        const amountWei = parseEther(row.amount);
        amounts.push(amountWei);
      })
      .on('end', () => {
        resolve();
      })
      .on('error', (error) => {
        reject(error);
      });
  });

  // Call the contract function
  try {
    // @ts-ignore
    const {request} = await publicClient.simulateContract({
      account,
      address: contractAddress as `0x${string}`,
      functionName: "setDistribution",
      abi: contractABI,
      args: [wallets, amounts],
    });

    // @ts-ignore
    const hash = await walletClient.writeContract(request)

    console.log('Transaction sent:', hash);

    // @ts-ignore
    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    console.log('Transaction successful:', receipt.transactionHash);


  } catch (error) {
    console.error('Error calling contract:', error);
  }
}

// Execute the function
processCsvAndCallContract();