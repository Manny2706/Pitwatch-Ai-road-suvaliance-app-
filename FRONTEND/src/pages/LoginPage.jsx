import Auth from "../components/Auth"
import FullAdminLogo from "../assets/FullAdminLogo.png"

function LoginPage() {
  return (
    <div className="bg-linear-to-r from-[#172033] to-[#456099] h-screen flex justify-evenly items-center">
      <div>
        <img src={FullAdminLogo} alt="admin logo" />
      </div>
      <Auth/>
    </div>
  )
}

export default LoginPage
