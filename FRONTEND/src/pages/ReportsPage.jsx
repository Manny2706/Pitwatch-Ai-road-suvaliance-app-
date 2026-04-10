import { useEffect, useState } from "react";
import axios from "axios";
import Navbar from "../components/Navbar";
import Sidebar from "../components/Sidebar";
import { ALL_REPORTS_API_ENDPOINT } from "../services/APIs";
import { FiSearch, FiFilter, FiDownload } from "react-icons/fi";
import { MdOutlineLocationOn } from "react-icons/md";
import { BsClockHistory } from "react-icons/bs";
import { TbAlertTriangle } from "react-icons/tb";

const SEVERITY_COLORS = {
  high:   { bg: "#FEE2E2", color: "#B91C1C" },
  medium: { bg: "#FEF9C3", color: "#92400E" },
  low:    { bg: "#DCFCE7", color: "#166534" },
};

const STATUS_COLORS = {
  pending:     { bg: "#EFF6FF", color: "#1D4ED8" },
  resolved:    { bg: "#F0FDF4", color: "#15803D" },
  in_progress: { bg: "#F0FDFA", color: "#0F766E" },
  ignored:     { bg: "#F9FAFB", color: "#6B7280" },
};

function Badge({ label, style }) {
  return (
    <span style={{
      padding: "3px 10px", borderRadius: 20, fontSize: 12,
      fontWeight: 500, whiteSpace: "nowrap", ...style
    }}>
      {label}
    </span>
  );
}

function ReportsPage() {
  const accessToken = localStorage.getItem("accessToken");
  const [reports, setReports]       = useState([]);
  const [page, setPage]             = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [pageSize]                  = useState(5);
  const [loading, setLoading]       = useState(false);
  const [search, setSearch]         = useState("");
  const [statusFilter, setStatus]   = useState("");
  const [severityFilter, setSeverity] = useState("");

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const res = await axios.get(ALL_REPORTS_API_ENDPOINT, {
          params: { page, page_size: pageSize },
          headers: { Authorization: `Bearer ${accessToken}` },
          withCredentials: true,
        });
        setReports(res.data.results);
        setTotalCount(res.data.total_count);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [page]);

  const totalPages = Math.ceil(totalCount / pageSize);
  const start      = (page - 1) * pageSize + 1;
  const end        = Math.min(page * pageSize, totalCount);

  const filtered = reports.filter((r) => {
    const q = search.toLowerCase();
    const matchSearch =
      !q ||
      String(r.id).includes(q) ||
      r.title?.toLowerCase().includes(q) ||
      r.description?.toLowerCase().includes(q);
    const matchStatus   = !statusFilter   || r.status   === statusFilter;
    const matchSeverity = !severityFilter || r.severity === severityFilter;
    return matchSearch && matchStatus && matchSeverity;
  });

  const handleExportCSV = () => {
    const headers = ["ID", "Type", "Severity", "Location", "Status", "Created At"];
    const rows = reports.map((r) => [
      r.id, r.description, r.severity, r.title, r.status, r.created_at,
    ]);
    const csv = [headers, ...rows].map((row) => row.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement("a");
    a.href = url; a.download = "reports.csv"; a.click();
  };

  return (
    <div className="flex flex-col h-screen overflow-hidden">
      <Navbar />
      <div className="flex flex-1 overflow-hidden">
        <Sidebar />
        <div className="flex-1 p-6 bg-[#E9ECF4]/30 flex flex-col gap-4 min-h-0 overflow-hidden">

          {/* Header */}
          <div>
            <h1 className="text-2xl font-bold">Hazard Reports</h1>
            <p className="text-gray-500 text-sm">Comprehensive data table with export options</p>
          </div>

          {/* Toolbar */}
          <div className="flex flex-wrap gap-2 items-center justify-between bg-white rounded-xl p-3 border border-gray-200">
            <div className="flex gap-2 flex-wrap flex-1">
              {/* Search */}
              <div className="flex items-center gap-2 border border-gray-200 rounded-lg px-3 py-1.5 text-sm bg-white min-w-50">
                <FiSearch className="text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by ID, location..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="outline-none bg-transparent w-full text-sm"
                />
              </div>

              {/* Status Filter */}
              <div className="flex items-center gap-1 border border-gray-200 rounded-lg px-3 py-1.5 text-sm bg-white cursor-pointer">
                <FiFilter className="text-gray-500" size={14} />
                <select
                  value={statusFilter}
                  onChange={(e) => setStatus(e.target.value)}
                  className="outline-none bg-transparent text-sm text-gray-700 cursor-pointer"
                >
                  <option value="">Status</option>
                  <option value="pending">Pending</option>
                  <option value="resolved">Resolved</option>
                  <option value="in_progress">In Progress</option>
                  <option value="ignored">Ignored</option>
                </select>
              </div>

              {/* Severity Filter */}
              <div className="flex items-center gap-1 border border-gray-200 rounded-lg px-3 py-1.5 text-sm bg-white cursor-pointer">
                <FiFilter className="text-gray-500" size={14} />
                <select
                  value={severityFilter}
                  onChange={(e) => setSeverity(e.target.value)}
                  className="outline-none bg-transparent text-sm text-gray-700 cursor-pointer"
                >
                  <option value="">Severity</option>
                  <option value="high">High</option>
                  <option value="medium">Medium</option>
                  <option value="low">Low</option>
                </select>
              </div>
            </div>

            {/* Export Buttons */}
            <div className="flex gap-2">
              <button
                onClick={handleExportCSV}
                className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white text-sm px-4 py-1.5 rounded-lg transition"
              >
                <FiDownload size={14} /> Export CSV
              </button>
            </div>
          </div>

          {/* Table */}
          <div className="bg-white rounded-xl border border-gray-200 flex flex-col flex-1 min-h-0 overflow-hidden">
            <div className="w-full text-sm">
              <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
                <tr>
                  {["ID", "Type", "Severity", "Location", "Status", "Timestamp"].map((h) => (
                    <th key={h} className="text-left px-4 py-3 font-medium">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={6} className="text-center py-10 text-gray-400">Loading...</td>
                  </tr>
                ) : filtered.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="text-center py-10 text-gray-400">No records found</td>
                  </tr>
                ) : (
                  filtered.map((r) => {
                    const sev = SEVERITY_COLORS[r.severity?.toLowerCase()] || SEVERITY_COLORS.low;
                    const sta = STATUS_COLORS[r.status?.toLowerCase()]     || STATUS_COLORS.ignored;
                    return (
                      <tr key={r.id} className="border-t border-gray-100 hover:bg-gray-50 transition">
                        {/* ID */}
                        <td className="px-4 py-4 font-medium text-gray-800">
                          HAZ-{String(r.id).padStart(3, "0")}
                        </td>

                        {/* Type */}
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1.5 text-gray-700">
                            <TbAlertTriangle size={15} className="text-gray-400" />
                            {r.description?.charAt(0).toUpperCase() + r.description?.slice(1)}
                          </div>
                        </td>

                        {/* Severity */}
                        <td className="px-4 py-4">
                          <Badge
                            label={r.severity?.charAt(0).toUpperCase() + r.severity?.slice(1) || "—"}
                            style={{ background: sev.bg, color: sev.color }}
                          />
                        </td>

                        {/* Location */}
                        <td className="px-4 py-4">
                          <div className="flex items-start gap-1 text-gray-700">
                            <MdOutlineLocationOn size={15} className="text-gray-400 mt-0.5 shrink-0" />
                            <span className="leading-tight">{r.title}</span>
                          </div>
                        </td>

                        {/* Status */}
                        <td className="px-4 py-4">
                          <Badge
                            label={r.status?.replace("_", " ").charAt(0).toUpperCase() + r.status?.replace("_", " ").slice(1) || "—"}
                            style={{ background: sta.bg, color: sta.color }}
                          />
                        </td>

                        {/* Timestamp */}
                        <td className="px-4 py-4 text-gray-500">
                          <div className="flex items-center gap-1.5">
                            <BsClockHistory size={13} />
                            {r.created_at
                              ? new Date(r.created_at).toLocaleString("en-IN", {
                                  year: "numeric", month: "2-digit",
                                  day: "2-digit",  hour: "2-digit", minute: "2-digit",
                                })
                              : "—"}
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
            </div>

            {/* Pagination */}
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100">
              <p className="text-sm text-gray-500">
                Showing <span className="font-medium">{start}–{end}</span> of{" "}
                <span className="font-medium">{totalCount}</span> records
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage((p) => Math.max(p - 1, 1))}
                  disabled={page === 1}
                  className="px-4 py-1.5 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 disabled:opacity-40 transition"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage((p) => Math.min(p + 1, totalPages))}
                  disabled={page === totalPages}
                  className="px-4 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-40 transition"
                >
                  Next
                </button>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

export default ReportsPage;