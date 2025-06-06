export default function CategoryGrid({ categories }) {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      {categories.map((c, i) => (
        <div key={i} className="bg-white rounded-xl p-4 flex flex-col items-center shadow">
          <img src={c.img} alt={c.label} className="h-20 w-20 object-cover rounded-lg" />
          <span className="mt-2 text-grey-dark font-medium">{c.label}</span>
        </div>
      ))}
    </div>
  )
}
