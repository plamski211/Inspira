/**
 * Debug component to show current breakpoint
 * Only visible in development mode
 *
 * @component
 * @example
 * <DebugCSS />
 */
export function DebugCSS() {
  if (process.env.NODE_ENV !== "development") return null

  return (
    <div className="fixed bottom-0 left-0 z-50 p-2 bg-white border shadow-md rounded-tr-md">
      <div className="block sm:hidden">XS (Mobile)</div>
      <div className="hidden sm:block md:hidden">SM (Small Tablet)</div>
      <div className="hidden md:block lg:hidden">MD (Large Tablet)</div>
      <div className="hidden lg:block xl:hidden">LG (Desktop)</div>
      <div className="hidden xl:block 2xl:hidden">XL (Large Desktop)</div>
      <div className="hidden 2xl:block">2XL (Extra Large)</div>
    </div>
  )
}
