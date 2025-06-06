export default function Card({ item }) {
  return (
    <div className="break-inside mb-6 bg-white rounded-2xl overflow-hidden shadow-md hover:shadow-xl transition-shadow duration-300">
      <img src={item.imageUrl} alt={item.title} className="w-full object-cover" />
      <div className="p-4">
        <h3 className="text-lg font-semibold text-gray-900 mb-1">{item.title}</h3>
        <p className="text-sm text-gray-600">by {item.author}</p>
      </div>
    </div>
  )
}
