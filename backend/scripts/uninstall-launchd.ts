const label = "com.healthmaxxing.server";
const plistPath = `${process.env.HOME}/Library/LaunchAgents/${label}.plist`;
const uid = process.getuid?.();

if (uid === undefined) {
  throw new Error("process.getuid() is unavailable on this platform");
}

await Bun.$`launchctl bootout gui/${uid} ${plistPath}`.quiet().nothrow();
await Bun.$`rm -f ${plistPath}`.quiet();

console.log(`Removed ${label}`);
