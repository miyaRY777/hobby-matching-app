module ApplicationHelper
  def primary_btn_class(size: :lg)
    base = "inline-flex items-center justify-center rounded-lg font-semibold"
    padding = size == :lg ? "px-8 py-3 text-lg" : "px-4 py-2 text-sm"
    "#{base} #{padding} bg-indigo-600 text-white hover:bg-indigo-700"
  end

  def outline_btn_class(size: :lg)
    base = "inline-flex items-center justify-center rounded-lg font-semibold"
    padding = size == :lg ? "px-8 py-3 text-lg" : "px-4 py-2 text-sm"
    "#{base} #{padding} border border-gray-300 bg-white text-gray-700 hover:bg-gray-50"
  end
end
