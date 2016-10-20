require "rufus-scheduler"
scheduler = Rufus::Scheduler.singleton

  def find_between(text, pre_string, post_string)
    matches = text.match(/#{pre_string}(.*?)#{post_string}/)
    if matches && matches.length > 1
      matches[1].strip
    else
      puts "Match failed!"
      puts "nothing between '#{pre_string}' & '#{post_string}'"
      puts "in #{text}"
      ""
    end
  end

  def extract_contract_data(text, contract_index)
    gov_entity = find_between(text, "Public Body:", "Contract Number:")
    gov_entity_contract_numb = find_between(text, "Contract Number:","Title:")
    contract_title = find_between(text, "Title:","Type of Contract:")
    contract_type = find_between(text, "Type of Contract:","Total Value of the Contract:")
    contract_value = (find_between(text, "Total Value of the Contract:","Start Date:").gsub(",","").gsub("$","").to_f).to_i
    begin
      contract_start = Date.parse(find_between(text, "Start Date:","Expiry Date:"))
    rescue
      contract_start = Date.parse("11/10/1979")
    end
    begin
      contract_end = Date.parse(find_between(text, "Expiry Date:","Status:"))
    rescue
      contract_end = Date.parse("11/10/1979")
    end
    contract_status = find_between(text, "Status:","UNSPSC :")
    contract_unspsc = find_between(text, "UNSPSC :","Description")
    { gov_entity: gov_entity,
      gov_entity_contract_numb: gov_entity_contract_numb,
      contract_title: contract_title,
      contract_type: contract_type,
      contract_value: contract_value,
      contract_start: contract_start,
      contract_end: contract_end,
      contract_status: contract_status,
      contract_unspsc: contract_unspsc,
      vt_contract_index: contract_index
    }
  end

  def store_or_skip(contract_data)
    if Contract.find_by(contract_number: contract_data[:gov_entity_contract_numb])
      puts "Skipping duplicate record"
    else
      puts "Storing contract #{contract_data[:gov_entity_contract_numb]}"
      Contract.create!(contract_number: contract_data[:gov_entity_contract_numb],
                       status: contract_data[:contract_status],
                       title: contract_data[:contract_title],
                       start_date: contract_data[:contract_start],
                       end_date: contract_data[:contract_end],
                       total_value: contract_data[:contract_value] )
    end
  end

  def scrape_department_ids(department_list_url)
    session = Capybara::Session.new(:poltergeist, {:js_errors => false})
    session.driver.browser.url_blacklist = @blacklist
    session.driver.browser.js_errors = false
    session.visit department_list_url
    department_indexes_to_scrape = []
    department_links = session.find_all("a#MSG2")
    department_links.each do |department_link|
      department_id = find_between(department_link[:href], "issuingBusinessId=", "&")
      @saved_date = department_link[:href][-10..-1]
      department_indexes_to_scrape.push(department_id)
      puts "Department (#{department_id}) - #{department_link[:text]} ::"
#      break if department_link.text.include?("Department of Education and Training") # Stop after third dep
    end
    session.driver.quit
    department_indexes_to_scrape
  end

  def scrape_contract_ids(department_indexes_to_scrape)
    contract_indexes = []
    department_indexes_to_scrape.each do |department_index|
      page_number = 1
      previous_page = ""
      current_page = "not blank"
      while previous_page != current_page
        previous_page = current_page
        department_session = Capybara::Session.new(:poltergeist, @options)
        department_session.driver.browser.url_blacklist = @blacklist
        department_session.driver.browser.js_errors = false
        puts "scanning department #{department_index} page #{page_number}"
        if page_number == 1
          department_url = "https://www.tenders.vic.gov.au/tenders/contract/list.do?showSearch=false&action=contract-search-submit&issuingBusinessId=#{department_index}&issuingBusinessIdForSort=#{department_index}&awardDateFromString=#{@saved_date}"
        else
          department_url = "https://www.tenders.vic.gov.au/tenders/contract/list.do?showSearch=false&action=contract-search-submit&issuingBusinessId=#{department_index}&issuingBusinessIdForSort=#{department_index}&pageNum=#{page_number}&awardDateFromString=#{@saved_date}"
        end
        department_session.visit department_url
        contract_links = department_session.find_all("a#MSG2")
        puts "CONTRACT LINKS FOR #{department_index} page #{page_number}"
        contract_links.each do |contract_link|
          puts "     - [#{contract_link["href"].to_s[59..63]}]"
          contract_indexes.push contract_link["href"].to_s[59..63]
#          break # stop after first contract
        end
        current_page = department_session.text
        department_session.driver.quit
        page_number += 1
      end
    end
    contract_indexes
  end

  def scrape_for_references(department_list_url)
    department_indexes_to_scrape = scrape_department_ids(department_list_url)
    puts "DEPS TO SCRAPE: #{department_indexes_to_scrape}"
    contract_indexes_to_scrape = scrape_contract_ids(department_indexes_to_scrape)
    puts "CONTS TO SCRAPE: #{contract_indexes_to_scrape}"
    contract_indexes_to_scrape
  end



daily_scrape = scheduler.every '1d', :first_at => Time.parse("11:30:00 pm") do #  '1h', :first_at => Time.now() + 5 do
  Rails.logger.info "Log || SCRAPE || At: #{Time.now}"

  require 'capybara/poltergeist'
  Capybara.javascript_driver = :poltergeist
  @options = { js_errors: false, timeout: 1800, phantomjs_logger: StringIO.new, logger: nil, phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes'] }
  @blacklist = ["https://maxcdn.bootstrapcdn.com/", "https://www.tenders.vic.gov.au/tenders/res/" ]
  @contract_indexes_to_scrape = scrape_for_references("https://www.tenders.vic.gov.au/tenders/contract/list.do?action=contract-view")

  contract_session = Capybara::Session.new(:poltergeist, @options)
  contract_session.driver.browser.url_blacklist = @blacklist
  contract_session.driver.browser.js_errors = false
  @contract_indexes_to_scrape.each do |contract_index|
    Rails.logger.info " :: Scraping #{contract_index}"
    contract_session.visit "http://www.tenders.vic.gov.au/tenders/contract/view.do?id=#{contract_index}"
    contract_data = extract_contract_data(contract_session.text, contract_index)
    store_or_skip(contract_data)
  end
  contract_session.driver.quit
  @scrapings = "Completed"
  Rails.logger.info " :: Completed Scraping ::"
end