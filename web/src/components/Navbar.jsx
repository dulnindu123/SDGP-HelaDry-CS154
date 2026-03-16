function Navbar() {
  return (
    <nav className="sticky top-0 z-50 bg-white shadow-md">

      <div className="max-w-6xl mx-auto flex justify-between items-center p-4">

        <div className="flex items-center gap-2">
          <img src="/logo.png" className="w-10"/>
          <h1 className="text-xl font-bold text-green-700">HelaDry</h1>
        </div>

        <ul className="flex gap-8 text-gray-700 font-medium">
          <li className="hover:text-green-700 cursor-pointer">Home</li>
          <li className="hover:text-green-700 cursor-pointer">Features</li>
          <li className="hover:text-green-700 cursor-pointer">Dashboard</li>
          <li className="hover:text-green-700 cursor-pointer">Team</li>
        </ul>

      </div>

    </nav>
  )
}

export default Navbar