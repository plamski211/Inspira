import PinCard from "./PinCard"

const MasonryLayout = ({ pins }) => {
  return (
    <div
      className="
      columns-1
      sm:columns-2
      md:columns-3
      lg:columns-4
      xl:columns-5
      gap-6
      max-w-7xl
      mx-auto
      py-6
      px-4
      "
    >
      {pins.map((pin) => (
        <PinCard
          key={pin.id}
          imageUrl={pin.imageUrl || "/assets/placeholder.jpg"}
          title={pin.title}
          creatorName={pin.creatorName}
        />
      ))}
    </div>
  )
}

export default MasonryLayout
