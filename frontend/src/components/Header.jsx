const Header = () => {
  return (
    <header>
      <div className="flex items-center space-x-4">
        <span className="text-orange-500 font-bold text-xl">Inspira</span>
        <nav className="space-x-4">
          <a href="/" className="text-gray-700 hover:text-orange-500">
            Home
          </a>
          <a href="/explore" className="text-gray-700 hover:text-orange-500">
            Explore
          </a>
        </nav>
      </div>
      <div>
        <button>Upload</button>
      </div>
    </header>
  )
}

export default Header
