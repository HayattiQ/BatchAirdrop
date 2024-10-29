import fs from 'fs';
import csv from 'csv-parser';
import dotenv from 'dotenv';

// Import the ABI from a JSON file
import contractABI from './abi.json';
import { parseEther } from 'viem';
import { account, publicClient, walletClient } from './client';

// Load environment variables
dotenv.config();

const startFrom = 0;
const batchSize = 500;
const initialNonce = 3356;

interface CsvRow {
  address: string;
  amount: string;
}

interface ProcessedData {
  wallets: `0x${string}`[];
  amounts: bigint[];
  errors: Array<{ line: number; address: string; amount: string; error: string }>;
}

async function processCsvFile(csvFilePath: string): Promise<ProcessedData> {
  const wallets: `0x${string}`[] = [];
  const amounts: bigint[] = [];
  const errors: Array<{ line: number; address: string; amount: string; error: string }> = [];
  let lineNumber = 0;

  return new Promise<ProcessedData>((resolve, reject) => {
    fs.createReadStream(csvFilePath)
      .pipe(csv())
      .on('data', (row: CsvRow) => {
        lineNumber++;
        try {
          if (!row.address || !row.amount) {
            throw new Error('Missing address or amount');
          }

          if (!row.address.startsWith('0x') || row.address.length !== 42) {
            throw new Error('Invalid Ethereum address format');
          }

          const cleanedAmount = row.amount.replace(/\,/g,"").replace(".00","");
          if (!/^\d+(\.\d+)?$/.test(cleanedAmount)) {
            throw new Error('Invalid amount format');
          }

          wallets.push(row.address as `0x${string}`);
          const amountWei = parseEther(cleanedAmount);
          amounts.push(amountWei);
        } catch (error) {
          errors.push({
            line: lineNumber,
            address: row.address,
            amount: row.amount,
            error: (error as Error).message
          });
          console.error(`Error processing line ${lineNumber}:`, {
            address: row.address,
            amount: row.amount,
            error: (error as Error).message
          });
        }
      })
      .on('end', () => {
        console.log(`CSV processing completed. Processed ${lineNumber} lines.`);
        if (errors.length > 0) {
          console.error(`Encountered ${errors.length} errors during processing.`);
        }
        resolve({ wallets, amounts, errors });
      })
      .on('error', (error) => {
        console.error('Error reading CSV file:', error);
        reject(error);
      });
  });
}

async function processBatches(data: ProcessedData, batchSize: number) {
  const { wallets, amounts } = data;
  const totalEntries = wallets.length;
  let currentNonce = initialNonce;

  for (let i = startFrom; i < totalEntries; i += batchSize) {
    const batchWallets = wallets.slice(i, i + batchSize);
    const batchAmounts = amounts.slice(i, i + batchSize);

    console.log(`Processing batch ${i / batchSize + 1}: entries ${i + 1} to ${Math.min(i + batchSize, totalEntries)}`);

    try {
      await callContract(batchWallets, batchAmounts, currentNonce);
      currentNonce += 1;
      console.log(`Batch ${i / batchSize + 1} processed successfully`);
    } catch (error) {
      console.error(`Error processing batch ${i / batchSize + 1}:`, error);
      break; // 処理を中断する場合
    }

  }
}


async function processCsvAndCallContract() {
  const csvFilePath = process.env.CSV_FILE_PATH;
  if ( !csvFilePath) {
    throw new Error('Missing environment variables. Please check your .env file.');
  }

  const walletData = await processCsvFile(csvFilePath)
  processBatches(walletData, batchSize)
}

async function callContract(wallets:`0x${string}`[], amounts: bigint[], nonce: number ) {
  const contractAddress = process.env.CONTRACT_ADDRESS;

  if ( !contractAddress ) {
    throw new Error('Missing environment variables. Please check your .env file.');
  }

    const {request} = await publicClient.simulateContract({
      account,
      address: contractAddress as `0x${string}`,
      functionName: "setDistribution",
      abi: contractABI,
      args: [wallets, amounts],
    });

    const hash = await walletClient.writeContract(request)

    console.log('Transaction sent:', hash);

    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    console.log('Transaction successful:', receipt.transactionHash);

}

// Execute the function
processCsvAndCallContract();