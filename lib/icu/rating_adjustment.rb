# A once-off adjustment to ICU ratings
# Motivation and details at https://www.icu.ie/system/downloads/000/000/505/8b01f5bb45f5ef325c201a7017564b232f585fc9.pdf

module ICU
  class RatingAdjustment
    ADJUSTMENT_DATE = ::Date.new(2024, 4, 1)

    def self.date
      ADJUSTMENT_DATE
    end

    def self.maybe_adjust(old, date)
      return old if date != ADJUSTMENT_DATE
      self.adjust old
    end

    private
    def self.adjust(old)
      return old if old >= 2000
      (old + 0.6 * (2000 - old)).to_i
    end
  end
end
