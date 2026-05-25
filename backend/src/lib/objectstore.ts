import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as grpc from "@grpc/grpc-js";
import * as protoLoader from "@grpc/proto-loader";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROTO_PATH = path.resolve(__dirname, "../../proto/objectstore.proto");
const DEFAULT_OBJECTSTORE_ADDRESS =
  process.env.OBJECTSTORE_GRPC_ADDRESS ?? "localhost:50054";

type UploadPdfRequest = {
  server_name: string;
  job_name: string;
  data: Buffer | Uint8Array;
  content_type: string;
};

type UploadPdfResponse = {
  success: boolean;
};

type ObjectStoreClient = grpc.Client & {
  UploadPdf(
    request: UploadPdfRequest,
    callback: grpc.requestCallback<UploadPdfResponse>,
  ): grpc.ClientUnaryCall;
};

type ObjectStoreProto = {
  objectstore: {
    ObjectStore: grpc.ServiceClientConstructor;
  };
};

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  defaults: true,
  enums: String,
  keepCase: true,
  longs: String,
  oneofs: true,
});

const objectStoreProto = grpc.loadPackageDefinition(
  packageDefinition,
) as unknown as ObjectStoreProto;

export type UploadPdfInput = {
  serverName: string;
  jobName: string;
  data: Buffer | Uint8Array;
  contentType?: string;
  address?: string;
};

export type UploadPdfFileInput = Omit<UploadPdfInput, "data"> & {
  filePath: string;
};

export function createObjectStoreClient(
  address = DEFAULT_OBJECTSTORE_ADDRESS,
): ObjectStoreClient {
  return new objectStoreProto.objectstore.ObjectStore(
    address,
    grpc.credentials.createInsecure(),
  ) as unknown as ObjectStoreClient;
}

export async function uploadPdf({
  serverName,
  jobName,
  data,
  contentType = "application/pdf",
  address,
}: UploadPdfInput): Promise<UploadPdfResponse> {
  const client = createObjectStoreClient(address);

  try {
    return await new Promise<UploadPdfResponse>((resolve, reject) => {
      client.UploadPdf(
        {
          server_name: serverName,
          job_name: jobName,
          data,
          content_type: contentType,
        },
        (error, response) => {
          if (error) {
            reject(error);
            return;
          }

          resolve(response ?? { success: false });
        },
      );
    });
  } finally {
    client.close();
  }
}

export async function uploadPdfFile({
  filePath,
  ...input
}: UploadPdfFileInput): Promise<UploadPdfResponse> {
  const data = await readFile(filePath);

  return uploadPdf({
    ...input,
    data,
  });
}
