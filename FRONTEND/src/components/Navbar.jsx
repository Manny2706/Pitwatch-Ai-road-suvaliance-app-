import AdminLogo from "../assets/AdminLogo.png";
import Logout from "../assets/Logout.png";
import { useState } from "react";
import LogoutPopup from "../services/Logout";

function Navbar() {
    const [showLogout, setShowLogout] = useState(false);
  return (
    <div className="flex p-[0.5%] justify-between items-center border-b border-gray-300 shadow-b shadow-md px-[2%] sticky top-0 z-50">
        <div className="flex gap-[5%]">
            <img 
            src={AdminLogo} 
            alt="admin logo" 
            className="w-[25%]"/>
            <div>
                <h1 className="text-xl font-bold">PitWatch Admin</h1>
                <p className="text-xs text-gray-500">Government Control Panel</p>
            </div>
        </div>
        <div className="flex gap-2">
            <div className="flex justify-end">
                <img 
                src={Logout} 
                alt="logout" 
                onClick={() => setShowLogout(!showLogout)}
                className="w-[20%] cursor-pointer transition-transform duration-200 hover:scale-110" />

                {showLogout && <LogoutPopup onClose = { () => setShowLogout(false)}/>}
            </div>
        </div>
      
    </div>
  )
}

export default Navbar
