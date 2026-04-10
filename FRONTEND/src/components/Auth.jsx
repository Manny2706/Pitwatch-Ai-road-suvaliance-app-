import Shield from "../assets/Shield.png";
import {MdPerson, MdLock,MdShield } from "react-icons/md";
import { HiOutlineEye, HiOutlineEyeOff } from "react-icons/hi";
import { AUTH_API_ENDPOINT } from "../services/APIs";
import toast from "react-hot-toast";
import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import axios from "axios";

function Auth() {
    const navigate = useNavigate(); 

    {/*Password Toggle*/}
    const [showPassword, setShowPassword] = useState(false);
    const toggle = () => setShowPassword(!showPassword);

     {/*Loading function*/}
    const [loading, setLoading] = useState(false);

     {/*Taking user input*/}
    const [data, setData] = useState({
        username:"",
        password:""});
    const changeEventHandler = (e) => {
        setData({...data,[e.target.name]:e.target.value});
    }

     {/*Sending data to backend*/}
    const submitHandler = async(e) => {
        e.preventDefault();
        setLoading(true);

        if (!data.username){
            toast.error("Invalid username");
            setLoading(false);
            return;
        }
        if (!data.password){
            toast.error("Invalid password");
            setLoading(false);
            return;
        }

         {/*API Integration*/}
        try{
            const loginRes = await axios.post(
                `${AUTH_API_ENDPOINT}login/`,
                data,{
                    headers:{
                        "Content-Type":"application/json"
                    },
                    withCredentials:true,
                }
            );
            console.log("Response Data: ", loginRes.data);
            localStorage.setItem("accessToken",loginRes.data.user.access);
            setLoading(false);
            toast.success("Login successful");
            navigate("/dashboard");

        }catch(error){
            toast.error(error.response?.data?.message || "Login Failed");
            console.log("Login error: ", error);
            console.log("Error response: ", error.response);
            setLoading(false);

        }
    }
  
  return (
    <div className="bg-[#385788B5] flex flex-col p-[1.5%] border border-gray-500 rounded-xl w-[30%]">
        {/* Form header */}
        <div className="flex gap-[2%] items-center">
            <div className="flex items-center justify-center">
                <img 
                src={Shield} 
                alt="shield" 
                className="object-contain w-[70%]"/>
            </div>
            <div className="flex flex-col">
                <h1 className="text-white font-bold text-2xl">PitWatch Admin</h1>
                <p className="text-xs text-[#22D3EE]">Government Control Panel</p>
            </div>
        </div>  

        {/* Form sub-header */}
        <div className="mt-[5%] mb-[5%]">
            <h1 className="text-xl font-bold text-white">Administrator Login</h1>
            <p className="text-sm text-white">Access secure monitoring dashboard</p>
        </div> 

        {/* Form  */}
        <form 
        className="flex flex-col"
        onSubmit={submitHandler}>

            {/* Username input */}
            <label 
            htmlFor="username" 
            className="text-lg text-white font-bold">Official Username</label>
            
            <div className="mt-[2%] border border-[#FFFFFF33] rounded-xl p-[1.5%] flex items-center gap-1 mb-[5%] bg-[#FFFFFF1A]">
                <MdPerson className="text-gray-300"/>
                <input 
                type="text" 
                id="userName" 
                name="username"
                value={data.username}
                onChange={changeEventHandler}
                placeholder="admin123" 
                className=" placeholder:text-gray-300 text-white bg-transparent w-full focus:outline-none caret-white"/>
            </div>

            {/* Password input */}
            <label 
            htmlFor="email" 
            className="text-lg text-white font-bold">Secure Password</label>
            
            <div className="border mt-[2%] border-[#FFFFFF33] bg-[#FFFFFF1A] rounded-xl p-[1.5%] flex items-center justify-between gap-1 mb-[5%]">
                <div className="flex justify-center items-center">
                    <MdLock className="text-gray-300"/>
                    <input 
                        type={showPassword ? "text" : "password"} 
                        id="password"
                        name="password"
                        value={data.password}
                        onChange={changeEventHandler} 
                        placeholder="Enter your password" 
                        className=" placeholder:text-gray-300  text-white ml-1 w-full focus:outline-none caret-white"/>
                </div>
                <div className="flex justify-end">
                    {showPassword?(
                        <HiOutlineEyeOff onClick={toggle} className="text-gray-300 cursor-pointer"/>
                    ):(
                        <HiOutlineEye onClick={toggle} className="text-gray-300 cursor-pointer"/>
                    )}
                </div>
            </div>

            <div className="border bg-[#22D3EE4D]/30 border-[#22D3EE4D]/90 rounded-xl p-[1.5%] flex items-center gap-1 mb-[5%]">
                <MdShield className="text-[#22D3EE4D]"/>
                <p className="text-white text-xs">This is a secure government portal. All activities are monitored and logged.</p>
            </div>

            {/* Submit button */}
            <button 
            className="shadow-lg bg-linear-to-r cursor-pointer from-[#1E3A8A] to-[#3B82F6] rounded-xl p-[1.5%] flex items-center justify-center gap-1 mb-[1%] disabled:opacity-70 disabled:cursor-not-allowed"
            type="submit"
            disabled={loading}>
                {loading ? (
                    <>
                        <div className="w-5 h-5 border-2  border-white border-t-transparent rounded-full animate-spin"></div>
                        <span className="text-white">Logging in...</span>
                    </>
                ):(
                    <>
                        <div className="w-5 h-5"></div>
                        <span className="text-white font-bold text-xl">Access Dashboard</span>
                    </>
                )}
            </button>

        </form>    
    </div>
  )
}

export default Auth
