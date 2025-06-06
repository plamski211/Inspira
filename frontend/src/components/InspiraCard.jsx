function InspiraCard({ title, description, imageUrl }) {
  return (
    <div className="bg-white shadow-sm rounded-md overflow-hidden">
      <img
        src={imageUrl || "/assets/placeholder.jpg"}
        alt={title}
        onError={(e) => {
          e.target.src = "/assets/placeholder.jpg"
        }}
        className="w-full h-64 object-cover"
      />
      <div className="p-4">
        <h2 className="text-lg font-semibold text-inspira-dark mb-2">{title}</h2>
        <p className="text-sm text-gray-600">{description}</p>
      </div>
    </div>
  )
}
export default InspiraCard
