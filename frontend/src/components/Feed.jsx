import Card from "./Card"

const sampleItems = Array.from({ length: 12 }).map((_, i) => ({
  id: i,
  title: `Creative Piece #${i + 1}`,
  author: `Artist ${i + 1}`,
  imageUrl: `https://picsum.photos/seed/${i + 1}/400/300`, // placeholder
}))

export default function Feed() {
  return (
    <div className="columns-1 sm:columns-2 lg:columns-3 xl:columns-4 gap-4 space-y-4">
      {sampleItems.map((item) => (
        <Card key={item.id} item={item} />
      ))}
    </div>
  )
}
