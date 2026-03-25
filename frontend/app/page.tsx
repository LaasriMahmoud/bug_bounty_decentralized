import { WalletConnect } from '@/components/WalletConnect';
import Link from 'next/link';

export default function DashboardPage() {
    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center py-10">
            <header className="w-full max-w-5xl flex justify-between items-center mb-10 px-5">
                <h1 className="text-3xl font-bold text-blue-900">Decentralized Bug Bounty</h1>
                <WalletConnect />
            </header>
            
            <main className="w-full max-w-5xl px-5 grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Bounties Section */}
                <section className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
                    <h2 className="text-xl font-semibold mb-4 text-gray-800">Active Bounties</h2>
                    <div className="space-y-4">
                        <div className="p-4 border border-blue-100 bg-blue-50/30 rounded-md">
                            <h3 className="font-bold text-lg text-blue-800">Protocol XYZ Smart Contract</h3>
                            <p className="text-gray-600 text-sm mt-1">Reward: 5000 USDC | Escrowed</p>
                            <p className="text-gray-600 text-sm">Stake Required: 50 USDC</p>
                            
                            <Link href="/submit">
                                <button className="mt-4 w-full bg-blue-600 text-white px-3 py-2 rounded-md text-sm font-medium hover:bg-blue-700 transition">
                                    Submit Vulnerability Report
                                </button>
                            </Link>
                        </div>
                    </div>
                </section>

                {/* My Submissions Section */}
                <section className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
                    <h2 className="text-xl font-semibold mb-4 text-gray-800">My Submissions</h2>
                    <div className="space-y-4">
                        <div className="p-4 border rounded-md flex justify-between items-center bg-gray-50">
                            <div>
                                <h3 className="font-semibold text-gray-800">Reentrancy in XYZ</h3>
                                <p className="text-gray-500 text-xs mt-1 font-mono">0x123...abc</p>
                            </div>
                            <span className="px-3 py-1 bg-yellow-100 text-yellow-800 text-xs font-semibold rounded-full">
                                Under Review
                            </span>
                        </div>
                    </div>
                </section>
            </main>
        </div>
    );
}
