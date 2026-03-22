module ApplicationHelper
  def primary_btn_class(size: :lg)
    base = "inline-flex items-center justify-center rounded-lg font-semibold"
    padding = size == :lg ? "px-8 py-3 text-lg" : "px-4 py-2 text-sm"
    "#{base} #{padding} bg-blue-600 text-white hover:bg-blue-700"
  end

  def outline_btn_class(size: :lg)
    base = "inline-flex items-center justify-center rounded-lg font-semibold"
    padding = size == :lg ? "px-8 py-3 text-lg" : "px-4 py-2 text-sm"
    "#{base} #{padding} border border-gray-600 text-gray-300 hover:bg-gray-800 hover:text-white"
  end
end
