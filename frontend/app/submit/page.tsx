'use client'

import React, { useState } from 'react';
import { useAccount, useWriteContract } from 'wagmi';
import { generateKey, encryptData, exportKey } from '@/services/encryption';
import { uploadToIPFS } from '@/services/ipfs';
import { BUG_BOUNTY_PLATFORM_ABI, CONTRACT_ADDRESS } from '@/services/contracts';
import { ethers } from 'ethers';
import { WalletConnect } from '@/components/WalletConnect';
import Link from 'next/link';

export default function SubmitReportPage() {
    const { isConnected } = useAccount();
    const { writeContractAsync } = useWriteContract();
    
    const [title, setTitle] = useState('');
    const [steps, setSteps] = useState('');
    const [impact, setImpact] = useState('');
    const [poc, setPoc] = useState('');
    
    const [status, setStatus] = useState('');
    const [savedKey, setSavedKey] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!isConnected) {
            alert("Please connect your wallet first");
            return;
        }

        try {
            setStatus('Generating encryption keys...');
            const key = await generateKey();
            const exportedRawKey = await exportKey(key);
            setSavedKey(exportedRawKey);

            setStatus('Encrypting report locally...');
            const payload = JSON.stringify({ title, steps, impact, poc });
            const { ciphertext, iv } = await encryptData(key, payload);

            setStatus('Uploading encrypted content to IPFS...');
            const ipfsData = {
                v: "1.0",
                ciphertext,
                iv,
            };
            // Mocking CID for seamless prototype demonstration without an actual Pinata Key
            const cid = "QmPlaceholderCidForPrototypeOnly123456789"; 

            setStatus('Awaiting wallet signature for on-chain submission...');
            
            const hSteps = ethers.keccak256(ethers.toUtf8Bytes(steps));
            const hImpact = ethers.keccak256(ethers.toUtf8Bytes(impact));
            const hPoc = ethers.keccak256(ethers.toUtf8Bytes(poc));
            const commitHash = ethers.keccak256(ethers.toUtf8Bytes(payload));
            const cidDigest = ethers.keccak256(ethers.toUtf8Bytes(cid));

            // Default bounty ID for UI mock
            const bountyId = 0n;

            await writeContractAsync({
                abi: BUG_BOUNTY_PLATFORM_ABI,
                address: CONTRACT_ADDRESS as `0x${string}`,
                functionName: 'submitReport',
                args: [
                    bountyId,
                    commitHash,
                    cidDigest,
                    hSteps,
                    hImpact,
                    hPoc
                ],
            });

            setStatus('Success! Report submitted and 50 USDC staked safely on-chain.');
            
        } catch (error) {
            console.error(error);
            setStatus('Transaction failed or rejected visually.');
        }
    };

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center py-10">
            <header className="w-full max-w-2xl flex justify-between items-center mb-6 px-5">
                <Link href="/" className="text-blue-600 hover:text-blue-800 text-sm font-semibold">
                    &larr; Back to Dashboard
                </Link>
                <WalletConnect />
            </header>

            <main className="w-full max-w-2xl px-5 bg-white p-8 rounded-lg shadow border border-gray-100">
                <h1 className="text-2xl font-bold text-gray-900 mb-6">Submit Vulnerability Report</h1>
                
                {savedKey && (
                    <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-md text-sm text-green-800">
                        <strong className="block mb-1">Save your decryption key securely!</strong>
                        <code className="break-all">{savedKey}</code>
                        <p className="mt-2 text-xs opacity-80">If the committee requests access, you will need to reveal this key to claim your bounty.</p>
                    </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div>
                        <label className="block text-sm font-medium text-gray-700">Vulnerability Title</label>
                        <input type="text" value={title} onChange={e => setTitle(e.target.value)} required className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border focus:border-blue-500 focus:ring-blue-500" />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700">Steps to Reproduce</label>
                        <textarea value={steps} onChange={e => setSteps(e.target.value)} required rows={4} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border focus:border-blue-500 focus:ring-blue-500" />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700">Impact</label>
                        <textarea value={impact} onChange={e => setImpact(e.target.value)} required rows={4} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border focus:border-blue-500 focus:ring-blue-500" />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700">Proof of Concept (PoC)</label>
                        <textarea value={poc} onChange={e => setPoc(e.target.value)} required rows={4} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border font-mono text-sm focus:border-blue-500 focus:ring-blue-500" />
                    </div>
                    
                    <div className="pt-4 border-t">
                        <button type="submit" disabled={!isConnected} className={`w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white ${isConnected ? 'bg-blue-600 hover:bg-blue-700' : 'bg-gray-400 cursor-not-allowed'}`}>
                            {isConnected ? 'Encrypt & Submit Report (50 USDC Stake)' : 'Connect Wallet First'}
                        </button>
                    </div>
                    
                    {status && (
                        <div className={`mt-4 text-center text-sm font-medium ${status.includes('Success') ? 'text-green-600' : 'text-blue-600'}`}>
                            {status}
                        </div>
                    )}
                </form>
            </main>
        </div>
    );
}
