module RmdHelpers
  def rmd_info_message(str)
    %(<span class="blue">#{str}</span>)
  end

  def rmd_success_message(str)
    %(<span class="green">#{str}</span>)
  end

  def rmd_warning_message(str)
    %(<span class="olive">#{str}</span>)
  end

  def rmd_error_message(str)
    %(<span class="brown">#{str}</span>)
  end
end
