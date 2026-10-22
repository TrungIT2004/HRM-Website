import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  allowedDevOrigins: ['localhost', '127.0.0.1', '*'],
  async redirects() {
    return [
      { source: '/dashboard', destination: '/home', permanent: false },
      { source: '/attendance', destination: '/attendance/overview', permanent: false },
      { source: '/leave', destination: '/attendance/leave', permanent: false },
      { source: '/overtime', destination: '/attendance/overtime', permanent: false },
      { source: '/organization', destination: '/organization/overview', permanent: false },
      { source: '/management', destination: '/management/overview', permanent: false },
      { source: '/security', destination: '/security/password', permanent: false },
      { source: '/admin', destination: '/admin/onboarding', permanent: false },
      { source: '/settings', destination: '/my-profile', permanent: false },
    ];
  },
  async rewrites() {
    const backendUrl = process.env.INTERNAL_BACKEND_URL || "http://hrm-backend:8080";
    return [
      {
        source: "/api/:path*",
        destination: `${backendUrl}/api/:path*`,
      },
      {
        source: "/auth/:path*",
        destination: `${backendUrl}/auth/:path*`,
      },
      {
        source: "/uploads/:path*",
        destination: `${backendUrl}/uploads/:path*`,
      },
      {
        source: "/ws/:path*",
        destination: `${backendUrl}/ws/:path*`,
      },
    ];
  },
};

export default nextConfig;

