import { useNavigate } from "react-router-dom";
import { AUTH_API_ENDPOINT } from "./APIs";
import toast from "react-hot-toast";
import axios from "axios";

function Logout({onClose}) {
    const navigate = useNavigate();
    
    const handleLogout = async () => {
        try{
            await axios.post(`${AUTH_API_ENDPOINT}logout/`);
            toast.success("Logged out successfully");
            localStorage.removeItem("accessToken");
            navigate("/");
        }catch{
            toast.error("Error")
        }  
  }; 

  return (
    <div className="absolute right-0 mt-12 w-64 bg-white rounded-xl shadow-xl p-4 z-50 animate-fadeIn">
        <p className="text-gray-800 font-semibold mb-3">
            Are you sure you want to logout?
        </p>

        <div className="flex justify-end gap-2">
            <button
            onClick={onClose}
            className="px-3 py-1 rounded-lg bg-gray-200 hover:bg-gray-300">
            Cancel
            </button>

            <button
            onClick={handleLogout}
            className="px-3 py-1 rounded-lg bg-red-500 text-white hover:bg-red-600">
            Logout
            </button>
        </div>
    </div>
  )
}

export default Logout
