import Growth from "../assets/Growth.png";
import Maps from "../assets/Maps.png";
import Reports from "../assets/Reports.png";
import { useNavigate } from "react-router-dom";

function Sidebar() {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col h-screen w-[20%] border-r-2 border-gray-200 pt-[2%] gap-[1%] pl-[2%]">
        <div onClick={() => navigate("/dashboard")} className="p-2 rounded-lg flex gap-2 items-center cursor-pointer transition-all duration-200 hover:scale-105 hover:translate-x-2 hover:bg-[#E9ECF4] w-[70%]">
            <img src={Growth} alt="growth" className="w-[10%]" />
            <h1 className="font-semibold text-gray-700 text-lg">Dashboard</h1>
        </div>
        <div onClick={() => navigate("/livemap")} className="p-2 rounded-lg flex gap-2 items-center cursor-pointer transition-all duration-200 hover:scale-105 hover:translate-x-2 hover:bg-[#E9ECF4] w-[70%]">
            <img src={Maps} alt="maps" className="w-[10%]" />
            <h1 className="font-semibold text-gray-700 text-lg">Live Map</h1>
        </div>
        <div onClick={() => navigate("/reports")} className="p-2 rounded-lg flex gap-2 items-center cursor-pointer transition-all duration-200 hover:scale-105 hover:translate-x-2 hover:bg-[#E9ECF4] w-[70%]">
            <img src={Reports} alt="reports" className="w-[10%]"/>
            <h1 className="font-semibold text-gray-700 text-lg">Reports</h1>
        </div>
    </div>
  )
}

export default Sidebar