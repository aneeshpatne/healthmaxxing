import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as grpc from "@grpc/grpc-js";
import * as protoLoader from "@grpc/proto-loader";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROTO_PATH = path.resolve(__dirname, "../../proto/objectstore.proto");
const DEFAULT_MARKITDOWN_ADDRESS =
  process.env.MARKITDOWN_GRPC_ADDRESS ?? "localhost:50055";

type ConvertPdfRequest = {
  pdf: Buffer | Uint8Array;
  filename: string;
};

export type ConvertPdfResponse = {
  markdown: string;
};

type MarkItDownClient = grpc.Client & {
  ConvertPdf(
    request: ConvertPdfRequest,
    callback: grpc.requestCallback<ConvertPdfResponse>,
  ): grpc.ClientUnaryCall;
};

type MarkItDownProto = {
  markitdown: {
    v1: {
      MarkItDownService: grpc.ServiceClientConstructor;
    };
  };
};

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  defaults: true,
  enums: String,
  keepCase: true,
  longs: String,
  oneofs: true,
});

const markItDownProto = grpc.loadPackageDefinition(
  packageDefinition,
) as unknown as MarkItDownProto;

export type ConvertPdfInput = {
  pdf: Buffer | Uint8Array;
  filename: string;
  address?: string;
};

export type ConvertPdfFileInput = {
  filePath: string;
  filename?: string;
  address?: string;
};

export function createMarkItDownClient(
  address = DEFAULT_MARKITDOWN_ADDRESS,
): MarkItDownClient {
  return new markItDownProto.markitdown.v1.MarkItDownService(
    address,
    grpc.credentials.createInsecure(),
  ) as unknown as MarkItDownClient;
}

export async function convertPdf({
  pdf,
  filename,
  address,
}: ConvertPdfInput): Promise<ConvertPdfResponse> {
  const client = createMarkItDownClient(address);

  try {
    return await new Promise<ConvertPdfResponse>((resolve, reject) => {
      client.ConvertPdf({ pdf, filename }, (error, response) => {
        if (error) {
          reject(error);
          return;
        }

        resolve(response ?? { markdown: "" });
      });
    });
  } finally {
    client.close();
  }
}

export async function convertPdfFile({
  filePath,
  filename = path.basename(filePath),
  address,
}: ConvertPdfFileInput): Promise<ConvertPdfResponse> {
  const pdf = await readFile(filePath);

  return convertPdf({
    pdf,
    filename,
    address,
  });
}
