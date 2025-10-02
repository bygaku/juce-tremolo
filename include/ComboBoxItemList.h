#pragma once

#include <algorithm>
#include <vector>

/** item list helper class
*/
template <typename T>
class ComboBoxItemList 
{
public:
    /** an entry in the list
    */
    struct Entry
    {
        T value;            //! The value
        juce::String name;  //! The display name
    };


    /** default constructor 
    */ 
    ComboBoxItemList() = default;


    /** constructor
        @param entries: list of entries to add
    */
    ComboBoxItemList (std::initializer_list<Entry> entries)
        : entries(entries) 
    {
    }


    /** apply to ComboBox
    */
    void applyTo (juce::ComboBox& comboBox) const
    {
        comboBox.clear();

        int id = 1;
        for (auto&& entry : entries) {
            comboBox.addItem (entry.name, id++);
        }
    }


    /** get id at value
        @param value: value in list
        @return id at value
    */
    int valueToId (const T& value) const
    {
        auto it = std::find_if (entries.begin(), entries.end(),
                                [value](const auto& e) { return e.value == value; });
                                
        if (it != entries.end()) {
            return static_cast<int> (std::distance (entries.begin(), it)) + 1;
        }

        return 0;
    }


    /** get value at id
        @param id: id in list
        @return value at id
    */
    T idToValue (int id) const
    {
        if (id > 0 && id <= static_cast<int> (entries.size())) {
            return entries[static_cast<size_t> (id - 1)].value;
        }

        return T();
    }


private:
    std::vector<Entry> entries;  //! the list of entries

};