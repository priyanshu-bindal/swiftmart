import TopBar from "@/components/TopBar";
import { Save, Plus, MoreVertical, Copy, Info, UserPlus } from "lucide-react";

const admins = [
  {
    name: "Alex Rivera",
    email: "alex.r@swiftmart.com",
    role: "Super Admin",
    roleColor: "bg-primary/10 text-primary",
    access: "Full System Access",
  },
  {
    name: "Sarah Jenkins",
    email: "s.jenkins@swiftmart.com",
    role: "Logistics Manager",
    roleColor: "bg-secondary-container/20 text-secondary",
    access: "Orders & Delivery Only",
  },
  {
    name: "Marc Chen",
    email: "chen.m@swiftmart.com",
    role: "Inventory Specialist",
    roleColor: "bg-surface-container-highest text-on-surface-variant",
    access: "Product & Catalog Only",
  },
];

const deliveryZones = [
  {
    name: "North America",
    details: "Standard: $12.00 • 3-5 days",
    dotColor: "bg-primary shadow-primary/40",
  },
  {
    name: "European Union",
    details: "Express: $25.00 • 2 days",
    dotColor: "bg-secondary shadow-secondary/40",
  },
];

export default function SettingsPage() {
  return (
    <>
      <TopBar placeholder="Search settings..." />
      <main className="p-8 bg-surface min-h-screen">
        <div className="max-w-6xl mx-auto">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-on-surface tracking-tight mb-2">
              System Settings
            </h1>
            <p className="text-on-surface-variant">
              Configure your store identity, delivery parameters, and payment
              integrations.
            </p>
          </div>

          {/* Settings Tabs */}
          <div className="flex gap-8 mb-10 border-b border-outline-variant/20">
            {["General", "Delivery", "Notifications", "Payment", "Admin Accounts"].map(
              (tab, i) => (
                <button
                  key={tab}
                  className={`pb-4 text-sm transition-all border-b-2 ${
                    i === 0
                      ? "font-bold border-primary text-primary"
                      : "font-medium text-on-surface-variant hover:text-primary border-transparent"
                  }`}
                >
                  {tab}
                </button>
              )
            )}
          </div>

          {/* Settings Grid */}
          <div className="grid grid-cols-12 gap-8">
            {/* Store Configuration */}
            <div className="col-span-12 lg:col-span-8 bg-surface-container-lowest rounded-xl p-8 shadow-sm">
              <div className="flex items-center justify-between mb-8">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center">
                    <span className="text-primary text-lg">🏪</span>
                  </div>
                  <h3 className="text-lg font-semibold text-on-surface">
                    Store Configuration
                  </h3>
                </div>
                <button className="px-5 py-2.5 bg-gradient-to-br from-primary to-primary-container text-white rounded-xl text-sm font-semibold hover:opacity-90 transition-opacity flex items-center gap-2">
                  <Save size={16} />
                  Save Changes
                </button>
              </div>
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                      Application Name
                    </label>
                    <input
                      type="text"
                      defaultValue="SwiftMart"
                      className="w-full bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all outline-none"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                      Store Tagline
                    </label>
                    <input
                      type="text"
                      defaultValue="Elevated Essentials for Modern Living"
                      className="w-full bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all outline-none"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                    Brand Logo
                  </label>
                  <div className="flex items-center gap-6 p-4 border-2 border-dashed border-outline-variant/30 rounded-xl bg-surface/50">
                    <div className="w-20 h-20 bg-surface-container-highest rounded-xl flex items-center justify-center text-3xl">
                      🏪
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium mb-1">Upload New Asset</p>
                      <p className="text-xs text-on-surface-variant">
                        SVG, PNG, or JPG (max. 800x400px)
                      </p>
                      <div className="mt-3 flex gap-3">
                        <button className="px-3 py-1.5 bg-surface-container-highest text-on-surface text-xs font-semibold rounded-lg hover:bg-outline-variant/20 transition-colors">
                          Choose File
                        </button>
                        <button className="px-3 py-1.5 text-error text-xs font-semibold rounded-lg hover:bg-error-container/20 transition-colors">
                          Remove
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Payment */}
            <div className="col-span-12 lg:col-span-4 space-y-8">
              <div className="bg-surface-container-lowest rounded-xl p-8 shadow-sm">
                <div className="flex items-center gap-3 mb-6">
                  <span className="text-secondary text-xl">💳</span>
                  <h3 className="text-lg font-semibold text-on-surface">
                    Payments
                  </h3>
                </div>
                <div className="space-y-6">
                  <div className="flex items-center justify-between p-4 bg-surface-container-low rounded-xl">
                    <div>
                      <p className="text-sm font-bold text-on-surface">
                        Cash on Delivery
                      </p>
                      <p className="text-xs text-on-surface-variant">
                        Allow customers to pay at door
                      </p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        className="sr-only peer"
                        defaultChecked
                      />
                      <div className="w-11 h-6 bg-outline-variant/30 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary" />
                    </label>
                  </div>
                  <div className="space-y-4 pt-4 border-t border-outline-variant/10">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 bg-indigo-600 rounded text-white text-[10px] font-black flex items-center justify-center">R</div>
                      <p className="text-sm font-bold text-on-surface">Razorpay Gateway</p>
                    </div>
                    <div className="space-y-3">
                      <div>
                        <label className="text-[10px] font-bold uppercase text-on-surface-variant">
                          API Key ID
                        </label>
                        <input
                          type="password"
                          defaultValue="rzp_live_v983nd92kd0"
                          className="w-full bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-2 text-xs focus:ring-2 focus:ring-primary/20 outline-none mt-1"
                        />
                      </div>
                      <div>
                        <label className="text-[10px] font-bold uppercase text-on-surface-variant">
                          Secret Key
                        </label>
                        <input
                          type="password"
                          defaultValue="••••••••••••••••"
                          className="w-full bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-2 text-xs focus:ring-2 focus:ring-primary/20 outline-none mt-1"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Delivery Zones */}
            <div className="col-span-12 lg:col-span-5 bg-surface-container-lowest rounded-xl p-8 shadow-sm">
              <div className="flex items-center justify-between mb-8">
                <div className="flex items-center gap-3">
                  <span className="text-primary text-xl">🚚</span>
                  <h3 className="text-lg font-semibold text-on-surface">
                    Delivery Zones
                  </h3>
                </div>
                <button className="w-8 h-8 flex items-center justify-center bg-primary/10 text-primary rounded-full hover:bg-primary hover:text-white transition-all">
                  <Plus size={16} />
                </button>
              </div>
              <div className="space-y-3">
                {deliveryZones.map((zone) => (
                  <div
                    key={zone.name}
                    className="group flex items-center justify-between p-4 bg-surface hover:bg-surface-container-low transition-colors rounded-xl"
                  >
                    <div className="flex items-center gap-4">
                      <div
                        className={`w-2 h-2 rounded-full ${zone.dotColor} shadow-[0_0_8px_rgba(0,0,0,0.2)]`}
                      />
                      <div>
                        <p className="text-sm font-bold text-on-surface">
                          {zone.name}
                        </p>
                        <p className="text-xs text-on-surface-variant">
                          {zone.details}
                        </p>
                      </div>
                    </div>
                    <MoreVertical
                      size={16}
                      className="text-on-surface-variant/40 group-hover:text-primary transition-colors cursor-pointer"
                    />
                  </div>
                ))}
                <div className="mt-6 pt-6 border-t border-outline-variant/10 grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold uppercase text-on-surface-variant">
                      Min. Order
                    </label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs text-on-surface-variant">
                        $
                      </span>
                      <input
                        type="number"
                        defaultValue={50}
                        className="w-full bg-surface-container-low border-none rounded-lg pl-6 pr-3 py-2 text-sm outline-none"
                      />
                    </div>
                  </div>
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold uppercase text-on-surface-variant">
                      Global Fee
                    </label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs text-on-surface-variant">
                        $
                      </span>
                      <input
                        type="number"
                        defaultValue={15}
                        className="w-full bg-surface-container-low border-none rounded-lg pl-6 pr-3 py-2 text-sm outline-none"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* FCM Notifications */}
            <div className="col-span-12 lg:col-span-7 bg-surface-container-lowest rounded-xl p-8 shadow-sm">
              <div className="flex items-center gap-3 mb-8">
                <span className="text-secondary text-xl">🔔</span>
                <h3 className="text-lg font-semibold text-on-surface">
                  Push Notifications (FCM)
                </h3>
              </div>
              <div className="space-y-6">
                <div className="space-y-2">
                  <label className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                    Server Key
                  </label>
                  <div className="relative">
                    <input
                      type="password"
                      defaultValue="AAAAZ1n-x9U:APA91bHkG_N0v..."
                      className="w-full bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-primary/20 outline-none font-mono"
                    />
                    <button className="absolute right-3 top-1/2 -translate-y-1/2 text-primary">
                      <Copy size={16} />
                    </button>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                      Project ID
                    </label>
                    <input
                      type="text"
                      defaultValue="swiftmart-prod-832"
                      className="w-full bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-primary/20 outline-none"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase tracking-wider text-on-surface-variant">
                      Sender ID
                    </label>
                    <input
                      type="text"
                      defaultValue="928374102934"
                      className="w-full bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-primary/20 outline-none"
                    />
                  </div>
                </div>
                <div className="flex items-center p-4 bg-secondary-container/10 rounded-xl gap-3">
                  <Info size={18} className="text-secondary shrink-0" />
                  <p className="text-xs text-on-secondary-container">
                    These credentials are used to send real-time order status
                    updates to your customers&apos; mobile devices.
                  </p>
                </div>
              </div>
            </div>

            {/* Admin Accounts */}
            <div className="col-span-12 bg-surface-container-lowest rounded-xl p-8 shadow-sm">
              <div className="flex items-center justify-between mb-8">
                <div className="flex items-center gap-3">
                  <span className="text-primary text-xl">👥</span>
                  <h3 className="text-lg font-semibold text-on-surface">
                    Admin Roles & Permissions
                  </h3>
                </div>
                <button className="px-5 py-2.5 bg-surface-container-high text-on-surface rounded-xl text-sm font-semibold hover:bg-surface-container-highest transition-colors flex items-center gap-2">
                  <UserPlus size={16} />
                  Invite Admin
                </button>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead>
                    <tr className="text-[10px] font-bold uppercase tracking-widest text-on-surface-variant border-b border-outline-variant/10">
                      {["User Identity", "Assigned Role", "Access Level", ""].map(
                        (h, i) => (
                          <th
                            key={h}
                            className={`pb-4 ${i === 0 ? "pl-4" : ""} ${
                              i === 3 ? "pr-4 text-right" : ""
                            }`}
                          >
                            {h}
                          </th>
                        )
                      )}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-outline-variant/5">
                    {admins.map((admin) => (
                      <tr
                        key={admin.email}
                        className="group hover:bg-surface-container-low/50 transition-colors"
                      >
                        <td className="py-5 pl-4">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-sm">
                              {admin.name
                                .split(" ")
                                .map((n) => n[0])
                                .join("")}
                            </div>
                            <div>
                              <p className="text-sm font-bold text-on-surface">
                                {admin.name}
                              </p>
                              <p className="text-xs text-on-surface-variant">
                                {admin.email}
                              </p>
                            </div>
                          </div>
                        </td>
                        <td className="py-5">
                          <span
                            className={`px-3 py-1 text-[10px] font-bold rounded-full uppercase tracking-tighter ${admin.roleColor}`}
                          >
                            {admin.role}
                          </span>
                        </td>
                        <td className="py-5">
                          <p className="text-xs text-on-surface-variant">
                            {admin.access}
                          </p>
                        </td>
                        <td className="py-5 text-right pr-4">
                          <button className="text-on-surface-variant hover:text-primary transition-colors">
                            <MoreVertical size={18} />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </main>
    </>
  );
}
