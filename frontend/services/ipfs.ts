import { create } from 'ipfs-http-client';

// We assume a local IPFS node, or Infura/Pinata if configured
const projectId = process.env.NEXT_PUBLIC_IPFS_PROJECT_ID || '';
const projectSecret = process.env.NEXT_PUBLIC_IPFS_PROJECT_SECRET || '';

const auth = "Basic " + Buffer.from(projectId + ":" + projectSecret).toString("base64");

// Initialize IPFS Client
export const ipfs = create({
    host: 'ipfs.infura.io',
    port: 5001,
    protocol: 'https',
    headers: {
        authorization: auth,
    },
});

/**
 * Upload JSON payload to IPFS and return the CID
 * @param data JSON object containing the report
 * @returns string CID
 */
export async function uploadToIPFS(data: any): Promise<string> {
    try {
        const result = await ipfs.add(JSON.stringify(data));
        return result.path;
    } catch (error) {
        console.error("IPFS Upload Error:", error);
        throw error;
    }
}

/**
 * Fetch content from IPFS by CID
 * @param cid IPFS Hash
 * @returns parsed JSON object
 */
export async function fetchFromIPFS(cid: string): Promise<any> {
    try {
        const stream = ipfs.cat(cid);
        const decoder = new TextDecoder();
        let data = '';
        for await (const chunk of stream) {
            data += decoder.decode(chunk, { stream: true });
        }
        return JSON.parse(data);
    } catch (error) {
        console.error("IPFS Fetch Error:", error);
        throw error;
    }
}
