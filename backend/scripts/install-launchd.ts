const label = "com.healthmaxxing.server";
const workdir = process.cwd();
const bunBin = Bun.which("bun");
const uid = process.getuid?.();

if (!bunBin) {
  throw new Error("bun binary not found in PATH");
}

if (uid === undefined) {
  throw new Error("process.getuid() is unavailable on this platform");
}

const templatePath = `${workdir}/launchd/${label}.plist.template`;
const template = await Bun.file(templatePath).text();

const launchAgentsDir = `${process.env.HOME}/Library/LaunchAgents`;
const logDir = `${workdir}/logs/launchd`;
const plistPath = `${launchAgentsDir}/${label}.plist`;
const stdoutPath = `${logDir}/${label}.stdout.log`;
const stderrPath = `${logDir}/${label}.stderr.log`;
const pathEnv = process.env.PATH ?? "/usr/bin:/bin:/usr/sbin:/sbin";

await Bun.$`mkdir -p ${launchAgentsDir} ${logDir}`.quiet();
await Bun.write(`${logDir}/.gitkeep`, "");

const plist = template
  .replaceAll("__BUN_BIN__", bunBin)
  .replaceAll("__WORKDIR__", workdir)
  .replaceAll("__PATH__", pathEnv)
  .replaceAll("__STDOUT_PATH__", stdoutPath)
  .replaceAll("__STDERR_PATH__", stderrPath);

await Bun.write(plistPath, plist);

await Bun.$`launchctl bootout gui/${uid}/${label}`.quiet().nothrow();
const bootstrap = await Bun.$`launchctl bootstrap gui/${uid} ${plistPath}`.nothrow();

if (bootstrap.exitCode !== 0) {
  throw new Error(`launchctl bootstrap failed:\n${bootstrap.stderr.toString()}`.trim());
}

const kickstart = await Bun.$`launchctl kickstart -k gui/${uid}/${label}`.nothrow();
if (kickstart.exitCode !== 0) {
  throw new Error(`launchctl kickstart failed:\n${kickstart.stderr.toString()}`.trim());
}

console.log(`Installed ${label}`);
console.log(`plist: ${plistPath}`);
console.log(`stdout: ${stdoutPath}`);
console.log(`stderr: ${stderrPath}`);
