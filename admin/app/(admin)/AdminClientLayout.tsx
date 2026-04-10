"use client";

import Sidebar from "@/components/Sidebar";
import { SidebarProvider, useSidebar } from "@/context/SidebarContext";
import { Toaster } from "react-hot-toast";

function AdminContent({ children }: { children: React.ReactNode }) {
  const { collapsed } = useSidebar();
  return (
    <div
      className={`
        flex-1 flex flex-col min-h-screen
        transition-[margin-left] duration-300 ease-in-out
        ${collapsed ? "ml-[72px]" : "ml-64"}
      `}
    >
      {children}
    </div>
  );
}

export default function AdminClientLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SidebarProvider>
      <div className="flex min-h-screen bg-surface">
        <Sidebar />
        <AdminContent>{children}</AdminContent>
      </div>
      <Toaster position="top-right" />
    </SidebarProvider>
  );
}
