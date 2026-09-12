import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  allowedDevOrigins: ['localhost', '127.0.0.1', '*'],
  async rewrites() {
    const backendUrl = process.env.INTERNAL_BACKEND_URL || "http://hrm-backend:8080";
    return [
      {
        source: "/api/:path*",
        destination: `${backendUrl}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;

